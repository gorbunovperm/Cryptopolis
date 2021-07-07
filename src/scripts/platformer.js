// TODO: Animations and Transaction may not been started and promises have never been resolved. You need to consider whether the animation/transaction is started.

var platformer = (() => { // module pattern

    let players = {};
    let playerAddresses = [];
    let fields;
    let fieldsPerLine = 10;
    let logsMessages = {};

    const FIELD_EMPTY = 0;
    const FIELD_COMPANY = 1;
    const FIELD_FEE = 2;
    const FIELD_CHANCE = 3;

    const EMPTY_OWNER = 0;

    const EMOJI_PIN = '&#x1F4CD;';
    const EMOJI_MONEY = '&#x1F4B0;';
    const EMOJI_TELEPORT = '&#x1F300;';
    const EMOJI_UPGRADE = '&#x1f53a;';
    const EMOJI_BUY = '&#x1f4bc;';
    const EMOJI_SLOT = '&#x1f3b0;';
    const RIGHT_ARROW = '<span class="lost">&rarr;</span>';
    const LEFT_ARROW = '<span class="won">&larr;</span>';
    const EMOJI_TIMER = '&#x23F3;';

    const Reason = { CroupierPenalty: 0, FieldSettlement: 1, NewRound: 2, Upgrade: 3, Downgrade: 4, FieldAcquisition: 5, CasinoLosing: 6, CasinoWinning: 7 };

    let playerAddressInitialized = (address, balance, qrcode) => {
        document.getElementById('managingAddress').innerText = address;
        document.getElementById('addressBalance').innerHTML = balance + ' ETH';
    };

    let drawFields = (map) => {
        fields = map.fields;

        fields.forEach((item, index, array) => {
            let field = document.createElement("div");
            field.className = 'field';
            //TODO: change EMPTY_OWNER to constant from smart-contract
            if (item.buyingRight != EMPTY_OWNER && item.owner == EMPTY_OWNER) {
                field.className += ` preliminary-owner preliminary-owner-${item.buyingRight}`;
            }
            field.className += ` owner-${item.owner}`;
            field.dataset.owner = item.owner;

            if (item.owner != EMPTY_OWNER) {
                field.className += ' developed';
            }

            if (item.type == 1) {
                field.className += ` group group-1`;
            }

            field.dataset.fieldId = index;

            field.id = `field-${index}`;

            let building = document.createElement("div");
            building.className = 'building';
            item.level = item.level != undefined ? item.level : 0;

            let developing = document.createElement("img");
            developing.src = "./src/img/gear.gif";
            developing.className = "loader";

            building.appendChild(developing);

            switch(parseInt(item.type)) {
                case FIELD_CHANCE:
                    building.className += ` casino`;
                    field.className += ' developed';
                    break;
                case FIELD_FEE:
                    building.className += ` tax`;
                    field.className += ' developed';
                    break;
                default:
                    building.className += ` level-${item.level}`;
                    break;
            }

            field.appendChild(building);

            let ground = document.createElement("div");
            ground.className = 'ground';
            let infoElement = document.createElement("div");
            infoElement.className = 'field_description';
            let stats = document.createElement("span");
            stats.className = 'stats';
            let buttons = document.createElement("span");
            buttons.className = 'buttons';
            let upgradeBtn = document.createElement("button");
            upgradeBtn.className = 'upgradeBtn';
            buttons.appendChild(upgradeBtn);
            let teleportBtn = document.createElement("button");
            teleportBtn.className = 'teleportBtn';
            teleportBtn.innerHTML = `${EMOJI_TELEPORT}`;
            teleportBtn.title = 'Teleport here';
            buttons.appendChild(teleportBtn);
            infoElement.appendChild(stats);
            infoElement.appendChild(document.createElement('br'));
            infoElement.appendChild(buttons);


            updateBuildingInfo(infoElement, item, index);
            building.appendChild(infoElement);

            field.appendChild(ground);

            document.getElementById('playground').appendChild(field);

            field.onmouseenter = (event) => {
                if (window.currentPlayerId == undefined) return;

                let playerAddress = playerAddresses[window.currentPlayerId];
                let player = players[playerAddress];
                let element = event.currentTarget;
                let teleportElement = element.getElementsByClassName('teleportBtn')[0];
                if (player.weapon_teleport > 0) {
                    teleportElement.removeAttribute('disabled');
                } else {
                    teleportElement.setAttribute('disabled', 'true')
                }

                
                let upgradeElement = element.getElementsByClassName('upgradeBtn')[0];
                let fieldId = element.dataset.fieldId;

                let fieldData = fields[element.dataset.fieldId];

                if (fieldData.level >= 4) return;

                if (fieldData.owner == window.currentPlayerId + 1 && fieldData.level < 4) {
                    element.classList.add('buildUp');
                    upgradeElement.innerHTML = `${EMOJI_UPGRADE}`;
                    upgradeElement.title = `Upgrade for $${fieldData.price}`;
                    upgradeElement.removeAttribute("disabled");
                } else if (fieldData.owner == EMPTY_OWNER && fieldData.buyingRight == window.currentPlayerId + 1) {
                    element.classList.add('buildUp');
                    upgradeElement.innerHTML = `${EMOJI_BUY}`;
                    upgradeElement.title = `Buy for $${fieldData.price}`;
                    upgradeElement.removeAttribute("disabled");
                } else if(upgradeElement.getAttribute("disabled") == null) {
                    upgradeElement.setAttribute("disabled", "true");
                }

            };

            field.onmouseleave = (event) => {
                element = event.currentTarget;
                //if (element.dataset.owner != undefined && window.currentPlayerId != undefined && element.dataset.owner == window.currentPlayerId) {
                    element.classList.remove('buildUp');
                //}
            }
        });
    };

    let updateBuildingInfo = (infoElement, item, index) => {

        let stats = infoElement.getElementsByClassName('stats')[0];
        let upgradeBtn = infoElement.querySelector('.buttons .upgradeBtn');
        let teleportElement = infoElement.querySelector('.buttons .teleportBtn');
        let cost = 0;
        stats.innerHTML = `${EMOJI_PIN} ${index}<br />`;
        switch (parseInt(item.type)) {
            case FIELD_EMPTY:
                stats.innerHTML += 'Start';
                break;

            case FIELD_COMPANY:
                cost = (parseInt(item.level) + 1) * item.price;
                stats.innerHTML += `Cost: $${cost}<br>Tax: $${item.payment}<br>Upgrade: $${item.price}`;
                break;

            case FIELD_FEE:
                stats.innerHTML += `Tax Office<br>Payment: $${item.payment}`;
                break;

            case FIELD_CHANCE:
                stats.innerHTML += `Casino`;
                break;
        }

        upgradeBtn.setAttribute('disabled', 'true');
        upgradeBtn.dataset.fieldId = index;

        teleportElement.dataset.fieldId = index;

        if (window.currentPlayerId == undefined) return;

        let playerAddress = playerAddresses[window.currentPlayerId];
        let player = players[playerAddress];
        if (player.weapon_teleport > 0) {
            teleportElement.removeAttribute('disabled');
        } else {
            teleportElement.setAttribute('disabled', 'true')
        }
    };

    let updateField = (fieldId, updatedField) => {
            outdatedField = fields[fieldId];
            fields[fieldId] = updatedField;

            let fieldElement = document.getElementById(`field-${fieldId}`);
            if (updatedField.owner != EMPTY_OWNER) {
                fieldElement.classList.remove('developing');
                fieldElement.classList.add('developed');
            }

            //TODO: make simple conditions and logic
            if (outdatedField.buyingRight == EMPTY_OWNER && updatedField.buyingRight != EMPTY_OWNER) {
                fieldElement.classList.add('preliminary-owner', `preliminary-owner-${updatedField.buyingRight}`);
            } else if (outdatedField.buyingRight != EMPTY_OWNER && updatedField.buyingRight == EMPTY_OWNER) {
                fieldElement.classList.remove('preliminary-owner');
                fieldElement.classList.remove(`preliminary-owner-${outdatedField.buyingRight}`);
            }

            fieldElement.classList.remove(`owner-${outdatedField.owner}`);
            let building = fieldElement.getElementsByClassName('building')[0];
            building.classList.remove(`level-${outdatedField.level}`);

            switch(parseInt(updatedField.type)) {
                case FIELD_CHANCE:
                    building.classList.add('casino');
                    fieldElement.classList.add('developed');
                    break;
                case FIELD_FEE:
                    building.classList.add('tax');
                    fieldElement.classList.add('developed');
                    break;
                case FIELD_COMPANY:
                    building.classList.add(`level-${updatedField.level}`);
                    fieldElement.classList.add(`owner-${updatedField.owner}`);
                    fieldElement.classList.add('group','group-1');
                    fieldElement.dataset.owner = updatedField.owner;
                    break;
            }

            let ground = fieldElement.getElementsByClassName('ground')[0];

            let info = fieldElement.getElementsByClassName('field_description')[0];
            updateBuildingInfo(info, updatedField, fieldId);
    };

    let playerLost = (playerAddress) => {
        playerAddress = playerAddress.toLowerCase();
        let playerStatElement = document.querySelector(`#statistics .player-${playerAddress}`);
        playerStatElement.className += ' lost';

        let playerElement = document.getElementById(`player-${playerAddress}`);
        playerElement.remove();
    };

    let prepareRequestingUpgrade = (fieldId) => {
        if (window.currentPlayerId == undefined) {
            return false;
        }
        let field = fields[fieldId];

        if (field.buyingRight == window.currentPlayerId + 1 || field.owner == window.currentPlayerId + 1) {
            let fieldElement = document.getElementById(`field-${fieldId}`);
            fieldElement.classList.add('developing');

            return true;
        }
    };

    let finalizeRequestingUpgrade = (fieldId) => {
        let fieldElement = document.getElementById(`field-${fieldId}`);
        fieldElement.classList.remove('developing');
    };

    let rollDice = () => {
        return Math.floor(1 + Math.random() * 3);
    };

    let turn = async (playerAddress, steps, newPosition) => {
        playerAddress = playerAddress.toLowerCase();
        let player = players[playerAddress];

        let playerElement = document.getElementById(`player-${playerAddress}`);
        if (steps == 0) {
            await playerChangePosition(playerAddress, newPosition, true);
            playerElement.classList.remove('showing');
            player.position = newPosition;            
        } else {
            playerElement.classList.add('walking');
            await movePlayer(playerAddress, newPosition);
            playerElement.classList.remove('showing');
            playerElement.classList.remove('walking');
        }

    };

    let movePlayer = async (playerAddress, toPosition) => {
        playerAddress = playerAddress.toLowerCase();
        let player = players[playerAddress];


        while (player.position != toPosition) {
            let stepTarget;
            let lastPositionAtCurrentLine = (Math.ceil((1 + player.position) / fieldsPerLine)) * fieldsPerLine - 1;
            let teleporting = false;

            if (player.position == lastPositionAtCurrentLine) {
                stepTarget = lastPositionAtCurrentLine + 1;
                if (stepTarget == fields.length) {
                    stepTarget = 0;
                }
                teleporting = true;

            } else if (toPosition < player.position
            || toPosition > lastPositionAtCurrentLine) {

                stepTarget = lastPositionAtCurrentLine;
            } else {
                stepTarget = toPosition;
            }

            await playerChangePosition(playerAddress, stepTarget, teleporting);
            player.position = stepTarget;
        }

        console.log(`Current user is ${playerAddress}`);
    };

    let playerChangePosition = async (playerAddress, newPosition, teleporting) => {
        playerAddress = playerAddress.toLowerCase();
        if(players[playerAddress].position == newPosition
        || players[playerAddress] == undefined) {
            console.log('Player position the same or the player is undefined.');
            return new Promise((resolve, reject) => {
                resolve();
            });
        }


        let playerElement = document.getElementById(`player-${playerAddress}`);
        let playerHeight = playerElement.offsetHeight;

        if (teleporting) {
            await playerHide(playerAddress);
        } else {
            playerElement.classList.remove('showing');
            playerElement.classList.add('walking');
        }

        targetField = document.getElementsByClassName('ground')[newPosition];
        playerElement.style.top = `${targetField.offsetTop - playerHeight}px`;
        playerElement.style.left = `${targetField.offsetLeft}px`;

        if (teleporting) {
            return playerShow(playerAddress);
        } else {
            return new Promise(function(resolve, reject) {
                playerElement.addEventListener("webkitTransitionEnd", function positionListener() {
                    resolve();
                    playerElement.removeEventListener("webkitTransitionEnd", arguments.callee);
                    console.log('Walking ended');
                });
            });
        }
    };


    let playerHide = (playerAddress) => {
        playerAddress = playerAddress.toLowerCase();
        let playerElement = document.getElementById(`player-${playerAddress}`);

        playerElement.classList.remove('walking');
        playerElement.classList.add('hiding');

        const promise = new Promise(function(resolve, reject) {
            playerElement.addEventListener("webkitAnimationEnd", function hideListener() {
                resolve();
                playerElement.removeEventListener("webkitAnimationEnd", arguments.callee);
                console.log('Hiding ended');
            });
        });

        return promise;
    };

    let playerShow = (playerAddress) => {
        playerAddress = playerAddress.toLowerCase();
        let playerElement = document.getElementById(`player-${playerAddress}`);

        playerElement.classList.remove('hiding');
        playerElement.classList.add('showing');

        const promise = new Promise(function(resolve, reject) {
            playerElement.addEventListener("webkitAnimationEnd", function showListener() {
                resolve();
                playerElement.removeEventListener("webkitAnimationEnd", arguments.callee);
                console.log('Showing ended');
            });
        });

        return promise;
    };


    let addPlayer = (playerAddress, skinType, position, balance, weapon_teleport, name, inGame) => {
        playerAddress = playerAddress.toLowerCase();
        players[playerAddress] = {
            type: skinType,
            position: parseInt(position),
            balance: balance,
            weapon_teleport: weapon_teleport,
            name: name,
            inGame: inGame
        };

        playerAddresses[skinType] = playerAddress;

        addPlayerStatistic(playerAddress, skinType, position, balance, weapon_teleport, name, inGame);
        if (players[playerAddress].inGame == false) return;

        let item = players[playerAddress];
        let player = document.createElement("div");
        player.className = `player type-${item.type}`;
        if(window.currentPlayerId != undefined && window.currentPlayerId == item.type) {
            player.className += ' myself';
        }
        player.id = `player-${playerAddress}`;

        let info = document.createElement("div");
        info.className = 'player-info';
        let nameElement = document.createElement("span");
        nameElement.className = 'nickname';
        nameElement.innerText = name;
        let decreasedBalance = document.createElement("div");
        decreasedBalance.innerText = '-10';
        decreasedBalance.className = 'decreased';
        decreasedBalance.style.top = '0px';

        info.appendChild(nameElement);
        info.appendChild(document.createElement("br"));
        info.appendChild(decreasedBalance);
        player.appendChild(info);


        let firstField = document.getElementsByClassName('ground')[item.position];

        document.getElementById('playground').appendChild(player);
        let playerHeight = player.offsetHeight;
        player.style.top = `${firstField.offsetTop - playerHeight}px`;
        player.style.left = `${firstField.offsetLeft}px`;

        if (window.currentPlayerId == undefined) {
            document.querySelector('.wrapper.buy-ticket').classList.remove('hidden');
            document.querySelector('input.buy-ticket').classList.remove('hidden');
            document.querySelector('.wrapper.next-turn').classList.add('hidden');
        } else {
            document.querySelector('.wrapper.buy-ticket').classList.add('hidden');
            document.querySelector('input.buy-ticket').classList.add('hidden');
            document.querySelector('.wrapper.next-turn').classList.remove('hidden');
        }

        changeCroupier();
    };

    let addPlayerStatistic = (playerAddress, skinType, position, balance, weapon_teleport, name, inGame) => {
        playerAddress = playerAddress.toLowerCase();

        let statisticsElement = document.getElementById('statistics');
        let playerStatistics = document.querySelector('#templates .player').cloneNode(true);

        playerStatistics.className += ` type-${skinType} player-${playerAddress}`;

        if (inGame == false) {
            playerStatistics.className += ' lost';
        }

        if(window.currentPlayerId != undefined && window.currentPlayerId == skinType) {
            playerStatistics.className += ' myself';
        }

        let nameElement = playerStatistics.getElementsByClassName('name')[0];
        nameElement.innerText = `${name}`;

        let balanceElement = playerStatistics.getElementsByClassName('balance')[0];
        balanceElement.innerText = `$${balance}`;

        statisticsElement.appendChild(playerStatistics);

        updateWeapons(playerAddress, weapon_teleport);
    }

    let updateBalance = (address, newBalance, change) => {
        address = address.toLowerCase();
        if (players[address] == undefined) {
            console.log('The player is undefined.');
            return;
        }
        let outdatedBalance = players[address].balance;
        let difference = newBalance - outdatedBalance;
        let infoElement = document.querySelector(`#player-${address} .player-info`);
        let decreasedBalanceElement = infoElement.getElementsByClassName('decreased')[0];
        decreasedBalanceElement.innerText = difference;

        players[address].balance = newBalance;
        document.querySelector(`#statistics .player-${address} .balance`).innerText = `${newBalance}$`;

        decreasedBalanceElement.className += ' decreasing';
        decreasedBalanceElement.style.top = '-100px';
        decreasedBalanceElement.addEventListener("webkitTransitionEnd", function decreased_webkitTransitionEnd() {
            decreasedBalanceElement.className = decreasedBalanceElement.className.replace('decreasing','');
            decreasedBalanceElement.style.top = '0px';
            console.log('Decreasing ended');
            decreasedBalanceElement.removeEventListener("webkitTransitionEnd", decreased_webkitTransitionEnd);
        });
    }

    let updateWeapons = (address, weapon_teleport) => {
        address = address.toLowerCase();

        let statisticsElement = document.getElementById('statistics');

        let weaponsElement = statisticsElement.querySelector(`.player-${address} .weapons`);
        let teleportElement = weaponsElement.getElementsByClassName('teleport')[0];

        if(weapon_teleport > 0) {
            teleportElement.style.display = 'block';
            teleportElement.title = `Teleports: ${weapon_teleport}`;
        } else {
            teleportElement.style.display = 'none';
        }

        players[address].weapon_teleport = weapon_teleport;
    }

    let removePlayer = (playerAddress) => {
        playerAddress = playerAddress.toLowerCase();
        document.getElementById(`player-${playerAddress}`).remove();
        delete players[playerAddress];
    };

    let logs = (event) => {
        let blockNumber = event.blockNumber;
        if (blockNumber == undefined) {
            console.log('Block undefined!', event);
        }
        let eventName = event.event;
        let logsElement = document.getElementById(`logs`);
        let blockElement;
        if (logsMessages[blockNumber] != true) {
            logsMessages[blockNumber] = true;
            blockElement = document.createElement('div');
            blockElement.id = `block-${blockNumber}`;
            blockElement.className = 'block';
            blockElement.innerHTML = `<span class="blockNumber">#${blockNumber}</span><br />`;
            logsElement.insertBefore(blockElement, logsElement.firstChild);
        } else {
            blockElement = logsElement.querySelector(`#block-${blockNumber}`);
        }
        let message = '';
        let classes = 'event';
        let address;
        let playerName;
        let value;

        if (event.returnValues.player != undefined) {
            address = event.returnValues.player.toLowerCase();
            playerName = players[address].name;

            if (players[address].type == window.currentPlayerId) {
                classes += ' bold';
            }
        }

        switch (eventName) {
            case "BalanceChanged":
                //event.returnValues.newBalance
                let change = event.returnValues.payment;
                let newBalance = event.returnValues.newBalance;
                let fieldId =  event.returnValues.fieldId;
                let reason =  parseInt(event.returnValues.reason);
                let reasonString = '';

                if(parseInt(change) == 0) {
                    return;
                }

                switch (reason) {
                    case Reason.CroupierPenalty:
                        reasonString = 'penalty for missing a move';
                    break;

                    case Reason.FieldSettlement:
                        reasonString = `accommodation on ${EMOJI_PIN} ${fieldId}`;
                    break;

                    case Reason.NewRound:
                        reasonString = `new round`;
                    break;

                    case Reason.Upgrade:
                        reasonString = `upgrade of ${EMOJI_PIN} ${fieldId}`;
                    break;

                    case Reason.Downgrade:
                        reasonString = `downgrade of ${EMOJI_PIN} ${fieldId}`;
                    break;

                    case Reason.FieldAcquisition:
                        reasonString = `buying of field ${EMOJI_PIN} ${fieldId}`;
                    break;

                    case Reason.CasinoLosing:
                        reasonString = `losing at the Casino ${EMOJI_PIN} ${fieldId}`;
                    break;

                    case Reason.CasinoWinning:
                        reasonString = `winning at the Casino ${EMOJI_PIN} ${fieldId}`;
                    break;
                }

                value = Math.abs(change);
                if (parseInt(change) <= 0) {
                    message = `<span class="${classes}"><span class="nickname">${playerName}</span> ${RIGHT_ARROW} $${value}<br><span class="reason">${reasonString}</span></span>`; // ${EMOJI_MONEY}${newBalance}
                } else {
                    message = `<span class="${classes}"><span class="nickname">${playerName}</span> ${LEFT_ARROW} $${value}<br><span class="reason">${reasonString}</span></span>`;
                }
                break;

            case "PositionChanged":
                let steps = event.returnValues.stepsNumber;
                let newPosition = event.returnValues.newPosition;
                if (steps > 0) {
                    message = `<span class="${classes}"><span class="nickname">${playerName}</span> took ${steps} steps. ${EMOJI_PIN}${newPosition}</span>`;
                } else {
                    message = `<span class="${classes}"><span class="nickname">${playerName}</span> teleported to ${EMOJI_PIN}${newPosition}</span>`;
                }
                break;

            case "CasinoResult":
                let typesResult = ['lost $', 'won $', 'got teleport '];
                let str = typesResult[event.returnValues.cardType];
                value = event.returnValues.value;
                message = `<span class="${classes}"><span class="nickname">${playerName}</span> ${str}${value}</span>`;
                break;

            case "croupierChanged":
                // message = `Now player ${event.returnValues.croupierId} makes a move.`
                break;
        }
        if (message != "") {
            blockElement.innerHTML += `${message}<br />`;
        }
    }

    let changeCroupier = () => {
        let croupierId = window.croupierId;
        if (croupierId != undefined) {
            let statisticsElement = document.getElementById('statistics');

            let croupierElement = statisticsElement.getElementsByClassName('croupier')[0];
            if (croupierElement != undefined) {
                croupierElement.className = croupierElement.className.replace('croupier', '');
                croupierElement.getElementsByClassName('dice')[0].innerHTML = '';
            }

            let playerStatistics = statisticsElement.getElementsByClassName(`type-${croupierId}`)[0];
            if (playerStatistics != undefined) {
                playerStatistics.className += ' croupier';
            }
        }

        toggleMakeMovesBtn();
    }

    let toggleMakeMovesBtn = () => {
        if (window.croupierId == undefined)
            return;

        let makeMovesBtn = document.getElementById('next-turn');
        let wrapper = document.querySelector(".wrapper.next-turn");
        let croupierId = window.croupierId;
        let transactionPending = window.movesTransactionPending == undefined ? false : window.movesTransactionPending;

        window.croupierExpired = window.croupierExpired == undefined ? false : window.croupierExpired;

        if (!window.croupierExpired && (croupierId != window.currentPlayerId || transactionPending)) {
            makeMovesBtn.setAttribute('disabled', 'true');
            wrapper.classList.add('disabled');
        } else {
            makeMovesBtn.removeAttribute('disabled');
            wrapper.classList.remove('disabled');
        }
    }

    let taxLevelUpdated = (taxPercent) => {
        let percentElement = document.getElementById('taxPercent');
        percentElement.innerText = `${taxPercent}%`;
    }

    let updateCroupierExpiration = (blocksLeft) => {
        let diceElement = document.querySelector('#statistics .player.croupier .dice');
        if (diceElement == undefined) {
            return;
        }
        let bl = blocksLeft < -99 ? -99 : blocksLeft;
        diceElement.innerHTML = `${EMOJI_TIMER}${bl}`;

        if (blocksLeft < 0) {
            window.croupierExpired = true;
            let playersElements = document.querySelectorAll('#statistics .player');
            [].forEach.call(playersElements, function(element) {
                if (!element.classList.contains('croupier')) {
                    element.classList.add('canBecomeCroupier');
                }
            });
        } else {
            window.croupierExpired = false;
            let croupierElements = document.querySelectorAll('#statistics .player.canBecomeCroupier');
            if (croupierElements == undefined) {
                return;
            }
            [].forEach.call(croupierElements, function(element) {
                element.classList.remove('canBecomeCroupier');
            });
        }
        toggleMakeMovesBtn();
    }

    return {
        turn: turn,
        addPlayer: addPlayer,
        players: players,
        drawFields: drawFields,
        updateField: updateField,
        updateBalance: updateBalance,
        updateWeapons: updateWeapons,
        logs: logs,
        changeCroupier: changeCroupier,
        prepareRequestingUpgrade: prepareRequestingUpgrade,
        finalizeRequestingUpgrade: finalizeRequestingUpgrade,
        playerLost: playerLost,
        taxLevelUpdated: taxLevelUpdated,
        toggleMakeMovesBtn: toggleMakeMovesBtn,
        updateCroupierExpiration: updateCroupierExpiration,
        playerAddressInitialized: playerAddressInitialized
    }
})();