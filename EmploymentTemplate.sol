// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EmploymentContract
 * @dev 劳动合同模板：用于雇佣双方自动管理工资支付、履约与终止条款。
 */
contract EmploymentContract {
    address public employer;      // 雇主地址
    address public employee;      // 员工地址
    uint256 public salary;        // 每月工资（单位：wei）
    uint256 public contractStart; // 合同起始时间
    uint256 public contractEnd;   // 合同结束时间
    uint256 public payCycle;      // 工资发放周期（单位：秒）
    uint256 public nextPayTime;   // 下一次工资发放时间
    bool public isActive;         // 合同是否有效

    event SalaryPaid(address employee, uint256 amount, uint256 timestamp);
    event ContractTerminated(string reason, uint256 timestamp);

    modifier onlyEmployer() {
        require(msg.sender == employer, "Only employer can perform this action.");
        _;
    }

    modifier onlyEmployee() {
        require(msg.sender == employee, "Only employee can perform this action.");
        _;
    }

    constructor(
        address _employee,
        uint256 _salary,
        uint256 _durationInMonths,
        uint256 _payCycleInDays
    ) payable {
        require(msg.value >= _salary * _durationInMonths, "Insufficient contract fund.");
        employer = msg.sender;
        employee = _employee;
        salary = _salary;
        contractStart = block.timestamp;
        contractEnd = contractStart + (_durationInMonths * 30 days);
        payCycle = _payCycleInDays * 1 days;
        nextPayTime = contractStart + payCycle;
        isActive = true;
    }

    /**
     * @dev 雇主支付工资，定期调用
     */
    function paySalary() public onlyEmployer {
        require(isActive, "Contract is not active.");
        require(block.timestamp >= nextPayTime, "Not time to pay yet.");
        require(address(this).balance >= salary, "Insufficient funds.");
        require(block.timestamp <= contractEnd, "Contract expired.");

        nextPayTime += payCycle;
        payable(employee).transfer(salary);
        emit SalaryPaid(employee, salary, block.timestamp);
    }

    /**
     * @dev 双方均可提前终止合同
     */
    function terminateByEmployer(string memory reason) public onlyEmployer {
        require(isActive, "Already terminated.");
        isActive = false;
        emit ContractTerminated(reason, block.timestamp);
    }

    function terminateByEmployee(string memory reason) public onlyEmployee {
        require(isActive, "Already terminated.");
        isActive = false;
        emit ContractTerminated(reason, block.timestamp);
    }

    /**
     * @dev 查询合同当前状态
     */
    function getStatus() public view returns (string memory) {
        if (!isActive) return "Terminated";
        if (block.timestamp > contractEnd) return "Expired";
        return "Active";
    }

    /**
     * @dev 合同结束后雇主可取回剩余工资（若提前终止）
     */
    function withdrawRemaining() public onlyEmployer {
        require(!isActive || block.timestamp > contractEnd, "Contract still active.");
        payable(employer).transfer(address(this).balance);
    }
}
