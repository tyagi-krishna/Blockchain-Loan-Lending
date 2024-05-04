// SPDX-License-Identifier: MT
pragma solidity ^0.8.0;

contract LoanSystem {
    address public owner;
    uint256 public totalLoans;

    struct Loan {
        uint256 amount;
        uint256 interestRate; // Interest rate in percentage (e.g., 5 for 5%)
        uint256 duration; // Duration of the loan in months
        uint256 monthlyFee; // Fee for each month's payment
        uint256 startTime;
        address borrower;
        address lender;
        bool isActive;
    }

    struct Payment {
        uint256 loanId;
        uint256 amount;
        uint256 timestamp;
    }

    mapping(uint256 => Loan) public loans;
    mapping(address => Payment[]) public payments;

    constructor() {
        owner = msg.sender;
    }

    function requestLoan(
        uint256 _amount,
        uint256 _interestRate,
        uint256 _duration
    ) external {
        uint256 loanId = totalLoans++;
        uint256 totalInterest = (_amount * _interestRate * _duration) / 100;
        uint256 monthlyFee = totalInterest / _duration;

        loans[loanId] = Loan({
            amount: _amount,
            interestRate: _interestRate,
            duration: _duration,
            monthlyFee: monthlyFee,
            startTime: block.timestamp,
            borrower: msg.sender,
            lender: address(0),
            isActive: true
        });
    }

    function lend(uint256 _loanId) external payable {
        Loan storage loan = loans[_loanId];
        require(loan.isActive, "Loan is not active");
        require(loan.lender == address(0), "Loan already funded");
        require(msg.value == loan.amount, "Incorrect amount sent");
        require(
            msg.sender != loan.borrower,
            "Borrower cannot lend to themselves"
        );

        loan.lender = msg.sender;
    }

    function repayLoan(uint256 _loanId) external payable {
        Loan storage loan = loans[_loanId];
        require(loan.isActive, "Loan is not active");
        require(
            msg.sender == loan.borrower,
            "Only the borrower can repay the loan"
        );
        require(msg.value >= loan.monthlyFee, "Insufficient payment amount");

        uint256 repaymentAmount = calculateRepaymentAmount(_loanId);
        require(msg.value >= repaymentAmount, "Incorrect amount sent");

        uint256 excessAmount = msg.value - repaymentAmount;
        if (excessAmount > 0) {
            payable(msg.sender).transfer(excessAmount); // Refund excess amount
        }

        // Record payment
        payments[msg.sender].push(
            Payment({
                loanId: _loanId,
                amount: repaymentAmount,
                timestamp: block.timestamp
            })
        );

        // Transfer payment to lender
        payable(loan.lender).transfer(loan.monthlyFee);

        if (isLoanFullyRepaid(_loanId)) {
            loan.isActive = false;
        }
    }

    function calculateRepaymentAmount(
        uint256 _loanId
    ) public view returns (uint256) {
        Loan storage loan = loans[_loanId];
        return loan.monthlyFee;
    }

    function getLoanHistory() external view returns (Loan[] memory) {
        Loan[] memory loanHistory = new Loan[](totalLoans);
        for (uint256 i = 0; i < totalLoans; i++) {
            loanHistory[i] = loans[i];
        }
        return loanHistory;
    }

    function getPaymentHistory(
        address _borrower
    ) external view returns (Payment[] memory) {
        return payments[_borrower];
    }

    function isLoanFullyRepaid(uint256 _loanId) public view returns (bool) {
        Loan storage loan = loans[_loanId];
        Payment[] storage borrowerPayments = payments[loan.borrower];
        uint256 totalPayments = 0;
        for (uint256 i = 0; i < borrowerPayments.length; i++) {
            if (borrowerPayments[i].loanId == _loanId) {
                totalPayments += borrowerPayments[i].amount;
            }
        }
        return
            totalPayments >= calculateRepaymentAmount(_loanId) * loan.duration;
    }
}
