pragma solidity ^0.4.25;

contract ElectronicContract {
    address public owner;
    address public notary;
    address[] public signers;
    uint public requiredSignatures;
    bool public isFinalized;
    string public contractHash;

    struct Signature {
        address signer;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    mapping(address => Signature) public signatures;
    mapping(address => bool) public hasSigned;
    uint public signCount;

    event ContractSigned(address indexed signer);
    event ContractFinalized(address indexed notary, string contractHash);
    event SignatureVerified(address indexed signer, bytes32 r, bytes32 s, uint8 v);

    modifier onlyNotary() {
        require(msg.sender == notary, "onlyNotary msg.sender == notary");
        _;
    }

    modifier onlySigner() {
        require(isSigner(msg.sender), "onlySigner _isSigner(msg.sender)");
        _;
    }

    constructor(address[] _signers, address _notary, string _contractHash) public {
        require(_signers.length > 0, "_signers.length > 0");
        owner = msg.sender;
        signers = _signers;
        notary = _notary;
        requiredSignatures = _signers.length;
        isFinalized = false;
        contractHash = _contractHash;
    }

    function isSigner(address _addr) public view returns (bool) { 
        for (uint i = 0; i < signers.length; i++) {
            if (signers[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    function signContract(bytes32 r, bytes32 s, uint8 v) public onlySigner {
        require(!hasSigned[msg.sender], "!hasSigned[msg.sender]");
        require(!isFinalized, "_!isFinalized");
        require(verifySignature(msg.sender, r, s, v), "verifySignature(msg.sender, r, s, v)");

        hasSigned[msg.sender] = true;
        signatures[msg.sender] = Signature(msg.sender, r, s, v);
        signCount++;

        emit SignatureVerified(msg.sender, r, s, v);  
        emit ContractSigned(msg.sender);

        if (signCount >= requiredSignatures) {
            finalizeContract();
        }
    }

    function verifySignature(address signer, bytes32 r, bytes32 s, uint8 v) internal view returns (bool) {  
        bytes32 messageHash = keccak256(bytes(contractHash));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        address recovered = ecrecover(ethSignedMessageHash, v, r, s);
        return (recovered == signer);
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {  
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)); 
    }

    function finalizeContract() internal {
        require(signCount >= requiredSignatures, " finalizeContract signCount >= requiredSignatures");
        isFinalized = true;
        emit ContractFinalized(notary, contractHash); 
    }

    // 获取合约哈希
    function getContractHash() public view returns (string) {
        return contractHash;
    }

    // 获取签名数量
    function getSignCount() public view returns (uint) {
        return signCount;
    }

    // 获取是否已完成签名
    function getIsFinalized() public view returns (bool) {
        return isFinalized;
    }

    // 获取指定签署人的签名信息
    function getSignature(address _signer) public view returns (bytes32, bytes32, uint8) {
        require(hasSigned[_signer], "Signer has not signed yet.");
        Signature storage sig = signatures[_signer];
        return (sig.r, sig.s, sig.v);
    }

    // 获取签署人地址列表
    function getSigners() public view returns (address[]) {
        return signers;
    }

    // 获取已签署的签署人地址列表
    function getSignedSigners() public view returns (address[]) {
        address[] memory signedSigners = new address[](signCount);
        uint counter = 0;
        for (uint i = 0; i < signers.length; i++) {
            if (hasSigned[signers[i]]) {
                signedSigners[counter] = signers[i];
                counter++;
            }
        }
        return signedSigners;
    }
}
