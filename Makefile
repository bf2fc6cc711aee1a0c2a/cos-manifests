MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
PROJECT_PATH := $(patsubst %/,%,$(dir $(MKFILE_PATH)))
LOCAL_BIN_PATH := ${PROJECT_PATH}/bin

ADDON_PATH := ${PROJECT_PATH}/addons/connectors-operator

OPERATOR_SDK_VERSION := v1.17.0

export PATH := ${LOCAL_BIN_PATH}:$(PATH)

bundles: bundle/camel-k bundle/strimzi bundle/cos-fleetshard-sync bundle/cos-fleetshard-operator-camel bundle/cos-fleetshard-operator-debezium

#
# bundles
#

bundle/camel-k: operator-sdk
	./hack/bundle.sh "camel-k" "camel-k-operator/$(ADDON_VERSION)"

bundle/strimzi: operator-sdk
	./hack/bundle.sh "strimzi" "strimzi-kafka-operator/$(ADDON_VERSION)"

bundle/cos-fleetshard-operator-camel: operator-sdk
	./hack/bundle.sh "cos-fleetshard-operator-camel" "cos-fleetshard-operator-camel/$(ADDON_VERSION)"
	
	cp hack/templates/operator-dependencies.yaml \
		$(ADDON_PATH)/cos-fleetshard-operator-camel-$(ADDON_VERSION)/metadata/dependencies.yaml
	
	yq -i '.dependencies[0].value.packageName="camel-k"' \
		$(ADDON_PATH)/cos-fleetshard-operator-camel-$(ADDON_VERSION)/metadata/dependencies.yaml
	yq -i '.dependencies[0].value.version=strenv(ADDON_VERSION)' \
		$(ADDON_PATH)/cos-fleetshard-operator-camel-$(ADDON_VERSION)/metadata/dependencies.yaml

bundle/cos-fleetshard-operator-debezium: operator-sdk
	./hack/bundle.sh "cos-fleetshard-operator-debezium" "cos-fleetshard-operator-debezium/$(ADDON_VERSION)"

	cp hack/templates/operator-dependencies.yaml \
		$(ADDON_PATH)/cos-fleetshard-operator-debezium-$(ADDON_VERSION)/metadata/dependencies.yaml

	yq -i '.dependencies[0].value.packageName="strimzi"' \
		$(ADDON_PATH)/cos-fleetshard-operator-debezium-$(ADDON_VERSION)/metadata/dependencies.yaml
	yq -i '.dependencies[0].value.version=strenv(ADDON_VERSION)' \
		$(ADDON_PATH)/cos-fleetshard-operator-debezium-$(ADDON_VERSION)/metadata/dependencies.yaml

bundle/cos-fleetshard-sync: operator-sdk
	./hack/bundle.sh "cos-fleetshard-sync" main/$(ADDON_VERSION)

	cp hack/templates/config.yaml \
		$(ADDON_PATH)/main
	cp hack/templates/main-dependencies.yaml \
		$(ADDON_PATH)/main/$(ADDON_VERSION)/metadata/dependencies.yaml

	yq -i '.dependencies[0].value.version=strenv(ADDON_VERSION)' \
		$(ADDON_PATH)/main/$(ADDON_VERSION)/metadata/dependencies.yaml
	yq -i '.dependencies[1].value.version=strenv(ADDON_VERSION)' \
		$(ADDON_PATH)/main/$(ADDON_VERSION)/metadata/dependencies.yaml

#
# Heleprs
#

operator-sdk:
ifeq (, $(shell command -v operator-sdk 2> /dev/null))
	@{ \
	set -e ;\
	if [ "$(shell uname -s 2>/dev/null || echo Unknown)" == "Darwin" ] ; then \
		curl \
			-L https://github.com/operator-framework/operator-sdk/releases/download/$(OPERATOR_SDK_VERSION)/operator-sdk_darwin_amd64 \
			-o operator-sdk ; \
	else \
		curl \
			-L https://github.com/operator-framework/operator-sdk/releases/download/$(OPERATOR_SDK_VERSION)/operator-sdk_linux_amd64 \
			-o operator-sdk ; \
	fi ;\
	chmod +x operator-sdk ;\
	mv operator-sdk $(LOCAL_BIN_PATH)/ ;\
	}
endif

#
# Heleprs
#

.PHONY: bundle/camel-k 
.PHONY: bundle/strimzi
.PHONY: cos-fleetshard-sync
.PHONY: cos-fleetshard-operator-camel
.PHONY: cos-fleetshard-operator-debezium
.PHONY: operator-sdk