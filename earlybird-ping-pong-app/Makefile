setup:
	yarn

run-local-chains:
	docker compose up -d

deploy-smart-contracts:
	forge build && forge install && ./deployment.sh

send-thunderbird-ping:
	cd script && ./sendPingOnThunderbirdPingPoingApp.sh && cd ../

send-rukh-ping:
	cd script && ./sendPingOnRukhPingPoingApp.sh && cd ../
