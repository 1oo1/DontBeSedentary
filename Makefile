APP_NAME = DontBeSedentary
BUILD_DIR = .build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources
INSTALL_DIR = /Applications

.PHONY: build run install uninstall clean

build: clean
	swift build -c release
	# Create .app bundle
	mkdir -p $(MACOS_DIR) $(RESOURCES_DIR)
	cp $(BUILD_DIR)/release/$(APP_NAME) $(MACOS_DIR)/$(APP_NAME)
	cp Sources/Info.plist $(CONTENTS_DIR)/Info.plist
	cp Resources/AppIcon.icns $(RESOURCES_DIR)/AppIcon.icns
	# Ad-hoc code sign
	codesign --force --sign - $(APP_BUNDLE)
	@echo "Built $(APP_BUNDLE)"

run: build
	open $(APP_BUNDLE)

uninstall:
	-pkill -x $(APP_NAME)
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Uninstalled $(INSTALL_DIR)/$(APP_NAME).app"

install: uninstall build
	cp -R $(APP_BUNDLE) $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"

clean:
	swift package clean
	rm -rf $(APP_BUNDLE)
	@echo "Cleaned."
