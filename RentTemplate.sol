// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RentContract
 * @dev 租房智能合约模板：自动化管理租期、租金支付和违约处理。
 */
contract RentContract {
    address public landlord;     // 房东地址
    address public tenant;       // 租客地址
    uint256 public rent;         // 每月租金（单位：wei）
    uint256 public startTime;    // 合同起始时间（时间戳）
    uint256 public endTime;      // 合同结束时间（时间戳）
    uint256 public payCycle;     // 支付周期（单位：秒）
    uint256 public nextDueTime;  // 下次应付款时间

    bool public isTerminated;    // 是否提前终止

    event RentPaid(address indexed tenant, uint256 amount, uint256 timestamp);
    event ContractTerminated(string reason, uint256 timestamp);

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only tenant can perform this action.");
        _;
    }

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only landlord can perform this action.");
        _;
    }

    constructor(
        address _tenant,
        uint256 _rent,
        uint256 _durationInMonths,
        uint256 _payCycleInDays
    ) {
        landlord = msg.sender;
        tenant = _tenant;
        rent = _rent;
        startTime = block.timestamp;
        endTime = startTime + (_durationInMonths * 30 days);
        payCycle = _payCycleInDays * 1 days;
        nextDueTime = startTime + payCycle;
    }

    /**
     * @dev 租客支付租金
     */
    function payRent() public payable onlyTenant {
        require(!isTerminated, "Contract is terminated.");
        require(block.timestamp <= endTime, "Contract expired.");
        require(msg.value == rent, "Incorrect rent amount.");
        require(block.timestamp >= nextDueTime, "Payment not due yet.");

        nextDueTime += payCycle;

        payable(landlord).transfer(msg.value);
        emit RentPaid(msg.sender, msg.value, block.timestamp);
    }

    /**
     * @dev 房东可在租客违约（超过7天未支付）时终止合同
     */
    function terminateByLandlord() public onlyLandlord {
        require(block.timestamp > nextDueTime + 7 days, "Tenant not overdue yet.");
        isTerminated = true;
        emit ContractTerminated("Terminated by landlord due to overdue rent", block.timestamp);
    }

    /**
     * @dev 租客可主动提前终止合同（如退租）
     */
    function terminateByTenant() public onlyTenant {
        require(block.timestamp < endTime, "Already expired.");
        isTerminated = true;
        emit ContractTerminated("Terminated by tenant", block.timestamp);
    }

    /**
     * @dev 查询合同是否仍在有效期内
     */
    function isActive() public view returns (bool) {
        return !isTerminated && block.timestamp < endTime;
    }
}
