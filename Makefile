APP_NAME = DontBeSedentary
BUILD_DIR = .build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
INSTALL_DIR = /Applications

.PHONY: build run install clean

build:
	swift build -c release
	# Create .app bundle
	mkdir -p $(MACOS_DIR)
	cp $(BUILD_DIR)/release/$(APP_NAME) $(MACOS_DIR)/$(APP_NAME)
	cp Sources/Info.plist $(CONTENTS_DIR)/Info.plist
	# Ad-hoc code sign
	codesign --force --sign - $(APP_BUNDLE)
	@echo "Built $(APP_BUNDLE)"

run: build
	open $(APP_BUNDLE)

install: build
	cp -R $(APP_BUNDLE) $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"

clean:
	swift package clean
	rm -rf $(APP_BUNDLE)
	@echo "Cleaned."
