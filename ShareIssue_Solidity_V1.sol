//This is the first version of a decentralized share issuance with a multisig functionality.

//Name: Azam Razman
//Date: 24 Dec 2016
//Time: 17:09:11
//Version: v1

/*
Intro: This is a contract for a proprietary share issuance on the Ethereum network. In this smart contract, we aim to have functionality of:
1. Share issuance, including more issuance in the future, i.e. not one time only.
2. Multisig functionality, i.e. the issuer must be multiple entity, and need multiple private keys to have approval of share issuance (and additional share issuance).
3. Additionally, any decision on the contract must have signature of multiple entity as well.
4. Only addresses approved will be able to receive and send the tokens (only to other approved addresses).
5. Authorized privatekey holders will be able to freeze transfer of shares of target addresses.
... (and many more to come)
*/

pragma solidity ^0.4.6;

//Inheritance allows a contract to acquire properties of a parent contract, without having to redefine all of them.
//Problem: This is single owned, not multi-owned... fixes expected in the future.
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    //Problem: Unfamiliar syntax... not sure whether it should be onlyOwner or onlyOwner()
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

//Initialize contract.
contract ShareIssue is owned {

	//Initialize the name of the token (shares).
	string public shareName;

	//Initialize the symbol the share. To simplify, this is basically the ticker name.
	string public shareSymbol;

	/* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    //Define the total supply of shares. 
    uint256 public totalSupply;

    /* This generates a public event on the blockchain that will notify clients */
    //We can consider this as a "notification".
    event Transfer(address indexed from, address indexed to, uint256 value);

    //Initital share issue. Only to be invoked in the case of an IPO.
    function initialShareIssue(uint256 initialSupply, string initialName, string initialSymbol) {

        balanceOf[msg.sender] = initialSupply;
        initialName = initialName;
        shareSymbol = initialSymbol;
    }

    //Problem: We want to be able to create more shares in the future, however, the function below only cater to single central entity... fixes expected in the future.
    function additionalShareIssue(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;

        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    function () {
        throw;     // Prevents accidental sending of ether.
    }

    //Allow regulators (and/or other authorized private key owners) to freeze moving of shares of target addresses.
    //<start>

    //This section does not make much sense on its own, please refer to the function transfer(address _to, uint256 _value) for more details.
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    //<end>

    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) {
            throw;           // Check if the sender has enough
        }

        if (balanceOf[_to] + _value < balanceOf[_to]) {
            throw; // Check for overflows
        }

        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place

        //Important: Throw the transaction if the target account is frozen.
        //Problem: Not sure whether this is the proper syntax. Maybe its just if(frozenAccount[msg.sender]) instead of if(frozenAccount[msg.sender] == true)
        if (frozenAccount[msg.sender] == true) {
            throw;
        }
    }  
}

/*
// ########## Start: Reference Only ##########

pragma solidity ^0.4.7;
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract MyToken {
    //Public variables of the token
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    //This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    //This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    //Initializes contract with initial supply tokens to the creator of the contract
    function MyToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }

    //Send coins
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    //Allow another contract to spend some tokens in your behalf
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    //Approve and then comunicate the approved contract in a single tx
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

    //A contract attempts to get the coins
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    //This unnamed function is called whenever someone tries to send ether to it
    function () {
        throw;     // Prevents accidental sending of ether
    }
}

//########## End: Reference Only ##########
*/
