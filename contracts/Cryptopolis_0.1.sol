pragma solidity 0.4.25;

contract Cryptopolis {
    uint256 public price = 0.001 ether; // 100 CLO
    uint256 public activePlayer = 0;
    uint256 public playersCount = 0;
    uint256 public maxPlayers = 5;
    address public owner;
    
    uint256 constant fieldsAmount = 10;
    uint256 constant goPassedReward = 200;
    uint256 constant initialFunds = 1500;
    
    mapping (address => bool) playerInGame;
    mapping (address => uint256) playerBalance;
    mapping (address => uint256) playerPosition;
    
    address[] public players;
    field[40] public fields;
    
    struct field {
        //uint8 fieldType;
        int256 payment;
    }
    
    event PositionChanged(address player, uint256 stepsNumber, uint256 newPosition);
    event BalanceChanged(address player, uint256 newBalance);
    
    
    constructor() public {
        fields[4].payment = -200;
        fields[5].payment = -200;
        owner = msg.sender;
    }
    
    function() payable public {
        emit BalanceChanged(msg.sender, 111);
        emit PositionChanged(msg.sender, 3, 3);
    }
    
    function buyTicket() payable public {
        require(msg.value == price);
        require(!playerInGame[msg.sender]);
        require(playersCount < maxPlayers);
        
        players.push(msg.sender);
        playerInGame[msg.sender] = true;
        playerBalance[msg.sender] = initialFunds;
        playerPosition[msg.sender] = 0;
        playersCount++;
        
        emit BalanceChanged(msg.sender, 0);
        emit PositionChanged(msg.sender, 0, 0);
    }
    
    function makeMove() public {
        require(playerInGame[msg.sender]);
        require(players[activePlayer] == msg.sender);

        uint256 stepsNumber = _countSteps();
        uint256 position = playerPosition[msg.sender];
        bool goPassed = false;
        
        position += stepsNumber;
        if (position >= fieldsAmount) {
            position = position - fieldsAmount;
            
        }
        require(position < fieldsAmount);
        playerPosition[msg.sender] = position;
        
        if (goPassed) {
            playerBalance[msg.sender] += goPassedReward;
        }
        
        // Check the payment in the field.
        // TODO: Check this condition.
        if (int256(playerBalance[msg.sender]) + fields[position].payment >= 0) {
            playerBalance[msg.sender] = uint256(int256(playerBalance[msg.sender]) + fields[position].payment);
        } else {
            // TODO: Should be implemented more behaviours, like sale of buildings.
            _playerLost(msg.sender);
        }
        
        emit BalanceChanged(msg.sender, playerBalance[msg.sender]);
        emit PositionChanged(msg.sender, stepsNumber, playerPosition[msg.sender]);

        activePlayer++;
        if (activePlayer == playersCount) {
            activePlayer = 0;
        }
    }
    
    function _countSteps() public returns(uint256) { // make Private
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender))) % 12;
    }
    
    function _playerLost(address player) public { // private
        require(playerInGame[player]);
        require(playersCount != 0);
        
        //delete players[playersCount] = msg.sender;
        playerInGame[player] = false;
        playerBalance[player] = 0;
        playerPosition[msg.sender] = 0;
        playersCount--;
    }
    

    function destruct() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
    
    
    
}