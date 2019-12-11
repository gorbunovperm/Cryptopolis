pragma solidity 0.4.25;

contract Cryptopolis {
    uint256 public price = 0.001 ether; // 100 CLO
    uint256 public croupierId = 0;
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
    Field[40] public fields;
    
    struct Field {
        //uint8 fieldType;
        int256 payment;
    }
    
    event PositionChanged(address player, uint256 stepsNumber, uint256 newPosition);
    event BalanceChanged(address player, uint256 newBalance);
    event NewPlayer(address player, uint256 skin);
    
    
    constructor() public {
        for(uint256 i = 0; i < fields.length; i++) {
            fields[i] = Field({payment: -100});
        }
        
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
        
        emit NewPlayer(msg.sender, players.length - 1);
        emit BalanceChanged(msg.sender, 0);
        emit PositionChanged(msg.sender, 0, 0);
    }
    
    function makeMoves() public {
        //address croupierAddress = players[croupierId];
        require(players[croupierId] == msg.sender);
        
        for (uint i = 0; i < players.length; i++) {
            _makeMove(players[i]);
        }
        
        croupierId++;
        if (croupierId == playersCount) {
            croupierId = 0;
        }
    }
    
    function _makeMove(address player) private {
        require(playerInGame[player]);

        uint256 stepsNumber = _countSteps(player);
        uint256 position = playerPosition[player];
        bool goPassed = false;
        
        position += stepsNumber;
        if (position >= fieldsAmount) {
            position = position - fieldsAmount;
            
        }
        require(position < fieldsAmount);
        playerPosition[player] = position;
        
        if (goPassed) {
            playerBalance[player] += goPassedReward;
        }
        
        // Check the payment in the field.
        // TODO: Check this condition.
        if (int256(playerBalance[player]) + fields[position].payment >= 0) {
            playerBalance[player] = uint256(int256(playerBalance[player]) + fields[position].payment);
        } else {
            // TODO: Should be implemented more behaviours, like sale of buildings.
            _playerLost(player);
        }
        
        emit BalanceChanged(player, playerBalance[player]);
        emit PositionChanged(player, stepsNumber, playerPosition[player]);

    }
    
    function _countSteps(address _player) public returns(uint256) { // make Private
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), _player))) % 12;
    }
    
    function _playerLost(address _player) public { // private
        require(playerInGame[_player]);
        require(playersCount != 0);
        
        //delete players[playersCount] = msg.sender;
        playerInGame[_player] = false;
        playerBalance[_player] = 0;
        playerPosition[msg.sender] = 0;
        playersCount--;
    }
    

    function destruct() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
    
    
    // View functions
    
    function getPlayers() public view returns(address[]){
        return players;
    }
    
}