pragma solidity ^0.4.25;
import "ElectronicContract.sol";

contract ContractFactory {
    address[] public deployedContracts;
    address public notary;
    address[] public signers;

    event ContractCreated(address contractAddress);
    event SignerAdded(address signer);

    constructor(address _notary) public {
        require(_notary != address(0), "Notary address cannot be zero.");
        notary = _notary;
    }

    function addSigner(address _signer) public {
        require(_signer != address(0), "Signer address cannot be zero.");
        signers.push(_signer);
        emit SignerAdded(_signer); 
    }

    function createContract(address[] _signers, string _contractHash) public returns (address) {
        require(_signers.length > 0, "At least one signatory is required to create a contract.");
        address newContract = new ElectronicContract(_signers, notary, _contractHash);
        deployedContracts.push(newContract);
        emit ContractCreated(newContract);  
        return newContract;
    }

    function getDeployedContracts() public view returns (address[]) { 
        return deployedContracts;
    }

    function getNotary() public view returns (address) { 
        return notary;
    }

    function getSigners() public view returns (address[]) {  
        return signers;
    }
}
