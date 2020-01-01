var map = { "fields": []};
var currentPlayerId;
var gasProvided_makeMoves = 8000000;
var gasPrice = 22000000000;
const TICKET_PRICE = 1000000000000000; // 0.001 eth
var gameStarted = false;
var maxPlayers = 2;
var currentBlockNumber = 0;
var croupierExpiration = 0;

window.addEventListener('load', async function() {

	const Web3 = require('web3');
	var Accounts = require('web3-eth-accounts');
	var provider = new Web3.providers.WebsocketProvider('wss://kovan.infura.io/ws/v3/311aeb20e7cb4c22914ad2b3f2a574f8');

	const web3 = new Web3(provider);

	var accountAddress;
	var events = {};
	var account;

	await web3.eth.net.isListening()
		.then(async () => {
			console.log('Web3 is connected');
			initAccount();
			web3.eth.getBalance(accountAddress).then(addressBalance => {
				window.platformer.playerAddressInitialized(accountAddress, web3.utils.fromWei(addressBalance));
			});
			const QRCode = require('qrcode');
			const generateQR = async text => {
				try {
				  document.getElementById('addressQr').src = await QRCode.toDataURL(text)
				} catch (err) {
				  console.error(err)
				}
			}
			generateQR(`ethereum:${accountAddress}`);

			setInterval(tick, 1000);
		})
		.catch(e => console.log('Wow. Something went wrong'));

	function initAccount() {
		account = JSON.parse(localStorage.getItem('account'));
		if(account === null) {
			account = web3.eth.accounts.create();
			localStorage.setItem('account', JSON.stringify(account));
		}
		accountAddress = account.address.toLowerCase();
	}

	const contractAddress = "0x950fcc965FAEA17e37fE94535d6Ec9044D1BaC84"; // private_2max kovan

	const cryptopolisAbi = [
		{
			"constant": false,
			"inputs": [
				{
					"name": "_owner",
					"type": "address"
				}
			],
			"name": "setOwner",
			"outputs": [],
			"payable": false,
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"constant": false,
			"inputs": [],
			"name": "makeMoves",
			"outputs": [],
			"payable": false,
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"constant": false,
			"inputs": [
				{
					"name": "position",
					"type": "uint8"
				}
			],
			"name": "teleport",
			"outputs": [],
			"payable": false,
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"constant": true,
			"inputs": [
				{
					"name": "",
					"type": "uint256"
				}
			],
			"name": "winner",
			"outputs": [
				{
					"name": "",
					"type": "address"
				}
			],
			"payable": false,
			"stateMutability": "view",
			"type": "function"
		},
		{
			"constant": true,
			"inputs": [],
			"name": "taxLevel",
			"outputs": [
				{
					"name": "",
					"type": "uint8"
				}
			],
			"payable": false,
			"stateMutability": "view",
			"type": "function"
		},
		{
			"constant": false,
			"inputs": [],
			"name": "destruct",
			"outputs": [],
			"payable": false,
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"constant": true,
			"inputs": [
				{
					"name": "_fieldId",
					"type": "uint8"
				}
			],
			"name": "getFields",
			"outputs": [
				{
					"name": "payment",
					"type": "uint256"
				},
				{
					"name": "owner",
					"type": "uint8"
				},
				{
					"name": "level",
					"type": "uint8"
				},
				{
					"name": "fieldType",
					"type": "uint8"
				},
				{
					"name": "price",
					"type": "uint256"
				},
				{
					"name": "buyingRight",
					"type": "uint8"
				}
			],
			"payable": false,
			"stateMutability": "view",
			"type": "function"
		},
		{
			"constant": true,
			"inputs": [
				{
					"name": "_playerId",
					"type": "uint8"
				}
			],
			"name": "getPlayer",
			"outputs": [
				{
					"name": "addr",
					"type": "address"
				},
				{
					"name": "position",
					"type": "uint256"
				},
				{
					"name": "balance",
					"type": "uint256"
				},
				{
					"name": "inGame",
					"type": "bool"
				},
				{
					"name": "weapon_teleport",
					"type": "uint256"
				},
				{
					"name": "name",
					"type": "string"
				}
			],
			"payable": false,
			"stateMutability": "view",
			"type": "function"
		},
		{
			"constant": true,
			"inputs": [
				{
					"name": "level",
					"type": "uint8"
				}
			],
			"name": "getLevelMultiplier",
			"outputs": [
				{
					"name": "",
					"type": "uint256"
				}
			],
			"payable": false,
			"stateMutability": "pure",
			"type": "function"
		},
		{
			"constant": false,
			"inputs": [],
			"name": "constructor2",
			"outputs": [],
			"payable": false,
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"constant": true,
			"inputs": [
				{
					"name": "",
					"type": "uint256"
				}
			],
			"name": "buyingRightExpiration",
			"outputs": [
				{
					"name": "",
					"type": "uint256"
				}
			],
			"payable": false,
			"stateMutability": "view",
			"type": "function"
		},
		{
			"constant": true,
			"inputs": [],
			"name": "currentGameId",
			"outputs": [
				{
					"name": "",
					"type": "uint256"
				}
			],
			"payable": false,
			"stateMutability": "view",
			"type": "function"
		},
		{
			"constant": false,
			"inputs": [
				{
					"name": "_fieldId",
					"type": "uint8"
				}
			],
			"name": "buildUp",
			"outputs": [],
			"payable": false,
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"constant": true,
			"inputs": [
				{
					"name": "",
					"type": "address"
				}
			],
			"name": "names",
			"outputs": [
				{
					"name": "",
					"type": "string"
				}
			],
			"payable": false,
			"stateMutability": "view",
			"type": "function"
		},
		{
			"constant": true,
			"inputs": [],
			"name": "playersEntered",
			"outputs": [
				{
					"name": "",
					"type": "uint8"
				}
			],
			"payable": false,
			"stateMutability": "view",
			"type": "function"
		},
		{
			"constant": true,
			"inputs": [],
			"name": "getPlayersCount",
			"outputs": [
				{
					"name": "",
					"type": "uint256"
				}
			],
			"payable": false,
			"stateMutability": "view",
			"type": "function"
		},
		{
			"constant": true,
			"inputs": [],
			"name": "croupierId",
			"outputs": [
				{
					"name": "",
					"type": "uint8"
				}
			],
			"payable": false,
			"stateMutability": "view",
			"type": "function"
		},
		{
			"constant": true,
			"inputs": [],
			"name": "getFieldsCount",
			"outputs": [
				{
					"name": "",
					"type": "uint256"
				}
			],
			"payable": false,
			"stateMutability": "view",
			"type": "function"
		},
		{
			"constant": true,
			"inputs": [],
			"name": "croupierExpiration",
			"outputs": [
				{
					"name": "",
					"type": "uint256"
				}
			],
			"payable": false,
			"stateMutability": "view",
			"type": "function"
		},
		{
			"constant": true,
			"inputs": [
				{
					"name": "",
					"type": "uint256"
				}
			],
			"name": "startBlockNumber",
			"outputs": [
				{
					"name": "",
					"type": "uint256"
				}
			],
			"payable": false,
			"stateMutability": "view",
			"type": "function"
		},
		{
			"constant": false,
			"inputs": [
				{
					"name": "_name",
					"type": "string"
				}
			],
			"name": "buyTicket",
			"outputs": [],
			"payable": true,
			"stateMutability": "payable",
			"type": "function"
		},
		{
			"inputs": [],
			"payable": false,
			"stateMutability": "nonpayable",
			"type": "constructor"
		},
		{
			"payable": false,
			"stateMutability": "nonpayable",
			"type": "fallback"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": false,
					"name": "player",
					"type": "address"
				},
				{
					"indexed": false,
					"name": "stepsNumber",
					"type": "uint8"
				},
				{
					"indexed": false,
					"name": "newPosition",
					"type": "uint8"
				}
			],
			"name": "PositionChanged",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": false,
					"name": "player",
					"type": "address"
				},
				{
					"indexed": false,
					"name": "newBalance",
					"type": "uint256"
				},
				{
					"indexed": false,
					"name": "payment",
					"type": "int256"
				},
				{
					"indexed": false,
					"name": "fieldId",
					"type": "uint8"
				},
				{
					"indexed": false,
					"name": "reason",
					"type": "uint8"
				}
			],
			"name": "BalanceChanged",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": false,
					"name": "player",
					"type": "address"
				},
				{
					"indexed": false,
					"name": "weapon_teleport",
					"type": "uint8"
				}
			],
			"name": "WeaponsChanged",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": false,
					"name": "player",
					"type": "address"
				},
				{
					"indexed": false,
					"name": "skin",
					"type": "uint8"
				},
				{
					"indexed": false,
					"name": "balance",
					"type": "uint256"
				},
				{
					"indexed": false,
					"name": "name",
					"type": "string"
				}
			],
			"name": "NewPlayer",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": false,
					"name": "player",
					"type": "address"
				}
			],
			"name": "PlayerLost",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": false,
					"name": "fieldId",
					"type": "uint8"
				},
				{
					"indexed": false,
					"name": "payment",
					"type": "uint256"
				},
				{
					"indexed": false,
					"name": "owner",
					"type": "uint8"
				},
				{
					"indexed": false,
					"name": "level",
					"type": "uint8"
				},
				{
					"indexed": false,
					"name": "fieldType",
					"type": "uint8"
				},
				{
					"indexed": false,
					"name": "price",
					"type": "uint256"
				},
				{
					"indexed": false,
					"name": "buyingRight",
					"type": "uint8"
				}
			],
			"name": "FieldUpdated",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": false,
					"name": "player",
					"type": "address"
				},
				{
					"indexed": false,
					"name": "cardType",
					"type": "uint8"
				},
				{
					"indexed": false,
					"name": "value",
					"type": "uint256"
				}
			],
			"name": "CasinoResult",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": false,
					"name": "croupierId",
					"type": "uint8"
				}
			],
			"name": "croupierChanged",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": false,
					"name": "taxPercent",
					"type": "uint256"
				}
			],
			"name": "TaxLevelUpdated",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": false,
					"name": "playerId",
					"type": "uint8"
				}
			],
			"name": "Penalty",
			"type": "event"
		}
	];

	var cryptopolisContract = new web3.eth.Contract(cryptopolisAbi, contractAddress);

	var startBlockNumber = 0;
	var currentGameId = 0;

	await cryptopolisContract.methods.currentGameId().call().then((gameId) => {
		currentGameId = gameId;
	});

	await cryptopolisContract.methods.startBlockNumber(currentGameId).call().then((blockNumber) => {
		startBlockNumber = blockNumber;
	});

	document.getElementById('next-turn').addEventListener("click", (event) => {
		window.movesTransactionPending = true;
		window.platformer.toggleMakeMovesBtn();

		const txMakeMoves = {
			from: accountAddress,
			to: contractAddress,
			gas: gasProvided_makeMoves,
			data: cryptopolisContract.methods.makeMoves().encodeABI()
		};

		const signPromise = web3.eth.accounts.signTransaction(txMakeMoves, account.privateKey);

		signPromise.then((signedTx) => {
			const sentTx = web3.eth.sendSignedTransaction(signedTx.raw || signedTx.rawTransaction);
			sentTx.on("receipt", receipt => {
				console.log('Move maked.', receipt);
				window.movesTransactionPending = false;
				window.platformer.toggleMakeMovesBtn();
			});
			sentTx.on("error", err => {
				window.movesTransactionPending = false;
				window.platformer.toggleMakeMovesBtn();
				console.log(err);
			});
		}).catch((err) => {
			console.log('Move rejected.', err);
			window.movesTransactionPending = false;
			window.platformer.toggleMakeMovesBtn();
		})
	});

	document.getElementById('buy-ticket').addEventListener("click", (event) => {
		let playerName = document.getElementById('player-name').value;

		const txBuyTicket = {
			from: accountAddress,
			to: contractAddress,
			gas: gasProvided_makeMoves,
			value: TICKET_PRICE,
			data: cryptopolisContract.methods.buyTicket(playerName).encodeABI()
		};

		const signPromise = web3.eth.accounts.signTransaction(txBuyTicket, account.privateKey);

		signPromise.then((signedTx) => {
			const sentTx = web3.eth.sendSignedTransaction(signedTx.raw || signedTx.rawTransaction);
			sentTx.on("receipt", receipt => {
			  console.log(receipt);
			});
			sentTx.on("error", err => {
			  console.log(err);
			});
		  }).catch((err) => {
			console.log(err);
		  });
	});


	function addFieldsEvents() {
		let buildUp_buttons = document.querySelectorAll(`.field .upgradeBtn`);

		for (var i = 0; i < buildUp_buttons.length; i++) {
			buildUp_buttons[i].addEventListener("click", function (event) {
				let fieldId = event.currentTarget.dataset.fieldId;
				if (window.platformer.prepareRequestingUpgrade(fieldId)) {
					const txBuildUp = {
						from: accountAddress,
						to: contractAddress,
						gas: gasProvided_makeMoves,
						data: cryptopolisContract.methods.buildUp(fieldId).encodeABI()
					};
			
					const signPromise = web3.eth.accounts.signTransaction(txBuildUp, account.privateKey);
			
					signPromise.then((signedTx) => {
						const sentTx = web3.eth.sendSignedTransaction(signedTx.raw || signedTx.rawTransaction);
						sentTx.on("receipt", receipt => {
							console.log('builing request sended.');
							console.log(receipt);
						});
						sentTx.on("error", err => {
							window.platformer.finalizeRequestingUpgrade(fieldId);
							console.log('builing request failed.');
							console.log(err);
						});
					}).catch((err) => {
						window.platformer.finalizeRequestingUpgrade(fieldId);
						console.log('builing request failed.');
						console.log(err);
					});
				}

			}, false);
		}

		let teleport_buttons = document.querySelectorAll(`.field .teleportBtn`);

		for (var i = 0; i < teleport_buttons.length; i++) {
			teleport_buttons[i].addEventListener("click", function (event) {
				let fieldId = event.currentTarget.dataset.fieldId;

				const txBuildUp = {
					from: accountAddress,
					to: contractAddress,
					gas: gasProvided_makeMoves,
					data: cryptopolisContract.methods.teleport(fieldId).encodeABI()
				};
		
				const signPromise = web3.eth.accounts.signTransaction(txBuildUp, account.privateKey);
		
				signPromise.then((signedTx) => {
					const sentTx = web3.eth.sendSignedTransaction(signedTx.raw || signedTx.rawTransaction);
					sentTx.on("receipt", receipt => {
						console.log('teleport request sended.');
						console.log(receipt);
					});
					sentTx.on("error", err => {
						console.log('teleport request failed.');
						console.log(err);
					});
				}).catch((err) => {
					console.log('teleport request failed.');
					console.log(err);
				});

			}, false);
		}

	}

	cryptopolisContract.methods.getFieldsCount().call().then((count) => {
		window.fieldsCount = parseInt(count);
		let fieldsReceived = 0;
		for(i = 0; i < count; i++) {
			let fieldId = i;
			cryptopolisContract.methods.getFields(fieldId).call().then(async function (field) {
				field.price = (field.price != undefined)?field.price:0;
				map.fields[fieldId] = {
					payment: field.payment,
					owner: field.owner,
					level: field.level,
					type: field.fieldType,
					group: field.group,
					price: field.price,
					buyingRight: field.buyingRight
				};

				fieldsReceived++;

				if (fieldsReceived == window.fieldsCount) {
					console.log('Fields data recieved.');
					window.platformer.drawFields(map);
					await getPlyersAndDraw();
					if(Object.keys(window.platformer.players).length == maxPlayers) {
						window.gameStarted = true;
					}

					cryptopolisContract.methods.taxLevel().call().then((tLevel) => {
						let taxPercent = 100 + parseInt(tLevel) * 10;
						window.platformer.taxLevelUpdated(taxPercent);
					});
					addFieldsEvents();

					
					cryptopolisContract.methods.croupierId().call().then((croupierId) => {
						window.croupierId = croupierId;
						window.platformer.changeCroupier();
					});

					cryptopolisContract.getPastEvents("allEvents", {
						fromBlock: startBlockNumber,
						toBlock: 'latest'
					},
					(error, evnts) => {
						console.log(evnts);
						let event;
						for (let i = 0; i < evnts.length; i++) {
							event = evnts[i];
							window.platformer.logs(event);
						}
						
					});
				}
			});
		}

	});


	function getPlyersAndDraw() {
		let result = new Promise(function(resolve, reject) {

			cryptopolisContract.methods.getPlayersCount().call().then(async (playersCount) => {

				console.log(`There are ${playersCount} players.`);
				if (playersCount == 0) {
					resolve();
				}
	
				for (let i = 0; i < playersCount; i++) {
					cryptopolisContract.methods.getPlayer(i).call().then( (player) => {
						if (player.addr.toLowerCase() == accountAddress) {
							window.currentPlayerId = i;
							resolve();
						} else if (i == playersCount - 1) {
							resolve();
						}
						window.platformer.addPlayer(player.addr, i, player.position, player.balance, player.weapon_teleport, player.name, player.inGame);
					});
				}
			});
		});



		return result;
	}



	cryptopolisContract.events.NewPlayer({
		fromBlock: 'latest'
	},
	(error, event) => {
		if (events[event.id] == true) return;
		events[event.id] = true;

		console.log(`New player added ${event.returnValues.player}`);
		
		if (event.returnValues.player.toLowerCase() == accountAddress) {
			window.currentPlayerId = event.returnValues.skin;
		}
		window.platformer.addPlayer(event.returnValues.player, event.returnValues.skin, 0, event.returnValues.balance, 0, event.returnValues.name, true);


		if (!window.gameStarted && Object.keys(window.platformer.players).length == maxPlayers) {
			updateAllFields();
			window.platformer.changeCroupier();
		}
	});

	function updateAllFields() {
		let fieldUpdated;
		for(let fieldId = 0; fieldId < window.fieldsCount; fieldId++) {
			cryptopolisContract.methods.getFields(fieldId).call().then(async function (field) {
				field.price = (field.price != undefined)?field.price:0;
				fieldUpdated = {
					payment: field.payment,
					owner: field.owner,
					level: field.level,
					type: field.fieldType,
					group: field.group,
					price: field.price,
					buyingRight: field.buyingRight
				};
				window.platformer.updateField(fieldId, fieldUpdated);
			});			
		}
	}


	cryptopolisContract.events.PositionChanged({
		fromBlock: 'latest'
	},
	(error, event) => {
		if (events[event.id] == true) return;
		events[event.id] = true;

		let playerAddress = event.returnValues.player;
		let steps = parseInt(event.returnValues.stepsNumber);
		let newPosition = parseInt(event.returnValues.newPosition);

		window.platformer.turn(playerAddress, steps, newPosition);

		window.platformer.logs(event);
	});

	cryptopolisContract.events.BalanceChanged({
		fromBlock: 'latest'
	},
	(error, event) => {
		console.log(`Event id: ${events[event.id]}`);
		if (events[event.id] == true) return;
		events[event.id] = true;

		window.platformer.updateBalance(event.returnValues.player, event.returnValues.newBalance, event.returnValues.payment);
		window.platformer.logs(event);
	});

	cryptopolisContract.events.PlayerLost({
		fromBlock: 'latest'
	},
	(error, event) => {
		if (events[event.id] == true) return;
		events[event.id] = true;

		window.platformer.playerLost(event.returnValues.player);
	});


	cryptopolisContract.events.FieldUpdated({
		fromBlock: 'latest'
	},
	(error, event) => {
		if (events[event.id] == true) return;
		events[event.id] = true;

		console.log(`Field ${event.returnValues.fieldId} updated.`);
		let field = {
			payment: event.returnValues.payment,
			owner: event.returnValues.owner,
			level: event.returnValues.level,
			type: event.returnValues.fieldType,
			group: event.returnValues.group,
			price: event.returnValues.price,
			buyingRight: event.returnValues.buyingRight
		};

		window.platformer.updateField(event.returnValues.fieldId, field);
	});


	cryptopolisContract.events.TaxLevelUpdated({
		fromBlock: 'latest'
	},
	(error, event) => {
		if (events[event.id] == true) return;
		events[event.id] = true;

		window.platformer.taxLevelUpdated(event.returnValues.taxPercent);
	});


	cryptopolisContract.events.WeaponsChanged({
		fromBlock: 'latest'
	},
	(error, event) => {
		if (events[event.id] == true) return;
		events[event.id] = true;

		console.log(`Weapons of ${event.returnValues.player} updated.`);

		window.platformer.updateWeapons(event.returnValues.player, event.returnValues.weapon_teleport);
		window.platformer.logs(event);
	});

	cryptopolisContract.events.CasinoResult({
		fromBlock: 'latest'
	},
	(error, event) => {
		if (events[event.id] == true) return;
		events[event.id] = true;

		window.platformer.logs(event);
	});

	cryptopolisContract.events.croupierChanged({
		fromBlock: 'latest'
	},
	(error, event) => {
		if (events[event.id] == true) return;
		events[event.id] = true;

		window.croupierId = event.returnValues.croupierId;
		window.platformer.changeCroupier();
		window.platformer.logs(event);
	});

	function tick() {
		getCroupierExpiration();
		checkNewBlock();
	}

	async function checkNewBlock() {
		let bn = await web3.eth.getBlockNumber();
		if (bn > currentBlockNumber) {
			currentBlockNumber = bn;
			let blocksLeft = croupierExpiration - currentBlockNumber;
			window.platformer.updateCroupierExpiration(blocksLeft);
		}
	}

	async function getCroupierExpiration() {
		croupierExpiration = await cryptopolisContract.methods.croupierExpiration().call();
	}

});