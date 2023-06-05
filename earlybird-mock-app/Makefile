setup:
	yarn

run-local-chains:
	docker compose up -d

deploy-smart-contracts:
	forge build && forge install && ./deployment.sh

send-thunderbird-message:
	cd script && sh ./sendMessageOnMockThunderbirdApp.sh && cd ../

send-rukh-message:
	cd script && sh ./sendMessageOnMockRukhApp.sh && cd ../

get-thunderbird-messages:
	cd script && sh ./getAllMessagesOnMockThunderbirdApp.sh && cd ../

get-rukh-messages:
	cd script && sh ./getAllMessagesOnMockRukhApp.sh && cd ../
