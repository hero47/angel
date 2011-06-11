package angel.roomedit {
	import angel.common.Alert;
	import angel.common.CatalogEntry;
	import angel.common.KludgeDialogBox;
	import angel.common.MessageCollector;
	import angel.common.SimplerButton;
	import angel.common.Tileset;
	import angel.common.Util;
	import fl.controls.ComboBox;
	import flash.display.Sprite;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CatalogEditUI extends Sprite {
		
		private var catalog:CatalogEdit;
		public var tilesPalette:FloorTilePalette;
		
		private var finishedEditNamesButton:SimplerButton;
		private var deleteTilesetButton:SimplerButton;
		
		private var newFilename:String;
		private var tilesetId:String;
		private var propId:String;
		
		public function CatalogEditUI(catalog:CatalogEdit) {
			this.catalog = catalog;
			
			var topButton:SimplerButton;
			var bottomButton:SimplerButton;
			var left:int = 10;
			
			topButton = new SimplerButton("Add tileset", clickedLoadTileset);
			topButton.x = left;
			topButton.y = 5;
			topButton.width = 100;
			addChild(topButton);
			left += topButton.width + 20;
			
			bottomButton = new SimplerButton("Edit tileset", clickedEditTileNames);
			bottomButton.width = topButton.width;
			Util.addBelow(bottomButton, topButton, 5);
			
			topButton = new SimplerButton("Add Prop", clickedAddProp);
			topButton.x = left;
			topButton.y = 5;
			topButton.width = 100;
			addChild(topButton);
			left += topButton.width + 20;
			
			bottomButton = new SimplerButton("Edit props", clickedEditProp);
			bottomButton.width = topButton.width;
			Util.addBelow(bottomButton, topButton, 5);
			
			topButton = new SimplerButton("Add Character", clickedAddChar);
			topButton.x = left;
			topButton.y = 5;
			topButton.width = 110;
			addChild(topButton);
			left += topButton.width + 20;
			
			bottomButton = new SimplerButton("Edit Characters", clickedEditChar);
			bottomButton.width = topButton.width;
			Util.addBelow(bottomButton, topButton, 5);
			
			topButton = new SimplerButton("Add Weapon", clickedAddWeapon);
			topButton.x = left;
			topButton.y = 5;
			topButton.width = 100;
			addChild(topButton);
			left += topButton.width + 20;
			
			bottomButton = new SimplerButton("Edit Weapons", clickedEditWeapon);
			bottomButton.width = topButton.width;
			Util.addBelow(bottomButton, topButton, 5);
			
			topButton = new SimplerButton("Add Splash", clickedAddSplash);
			topButton.x = left;
			topButton.y = 5;
			topButton.width = 100;
			addChild(topButton);
			left += topButton.width + 20;
			
			bottomButton = new SimplerButton("Edit Splashs", clickedEditSplash);
			bottomButton.width = topButton.width;
			Util.addBelow(bottomButton, topButton, 5);
			
			topButton = new SimplerButton("Save Catalog", clickedSaveCatalog);
			topButton.x = left;
			topButton.y = 5;
			topButton.width = 100;
			addChild(topButton);
			left += topButton.width + 10;
			
			topButton = new SimplerButton("Edit Room", clickedEditRoom);
			topButton.x = left;
			topButton.y = 5;
			topButton.width = 100;
			addChild(topButton);
			left += topButton.width + 5;
			
			
			finishedEditNamesButton = new SimplerButton("Keep these names", clickedEditNamesDone, 0x00ffff);
			finishedEditNamesButton.width = 200;
			addChild(finishedEditNamesButton);
			finishedEditNamesButton.visible = false;
			
			deleteTilesetButton = new SimplerButton("Delete from catalog", clickedDeleteTileset, 0xff0000);
			deleteTilesetButton.width = 200;
			addChild(deleteTilesetButton);
			deleteTilesetButton.visible = false;
		}
		
		private function clickedLoadTileset(event:Event):void {
			new FileChooser(userSelectedNewTilesetFile, null, false);
		}
		
		private function userSelectedNewTilesetFile(filename:String):void {
			newFilename = filename;
			launchIdDialog("tileset", userEnteredNameForNewTileset);
		}
		
		private function clickedAddChar(event:Event):void {
			new FileChooser(userSelectedNewCharFile, null, false);
		}
		
		private function userSelectedNewCharFile(filename:String):void {
			newFilename = filename;
			launchIdDialog("character", userEnteredNameForNewChar);
		}
		
		private function clickedAddProp(event:Event):void {
			new FileChooser(userSelectedNewPropFile, null, false);
		}
		
		private function userSelectedNewPropFile(filename:String):void {
			newFilename = filename;
			launchIdDialog("prop", userEnteredNameForNewProp);
		}
		
		private function clickedAddWeapon(event:Event):void {
			newFilename = "";
			launchIdDialog("weapon", userEnteredNameForNewWeapon);
		}
		
		private function clickedAddSplash(event:Event):void {
			new FileChooser(userSelectedNewSplashFile, null, false);
		}
		
		private function userSelectedNewSplashFile(filename:String):void {
			newFilename = filename;
			launchIdDialog("splash", userEnteredNameForNewSplash);
		}
		
		public function launchIdDialog(idForWhat:String, callback:Function, previousError:String = null):void {
			//var filename:String = newlyLoadedTileset.catalogEntry.filename;
			//var defaultIdBase:String = filename.slice(0, filename.lastIndexOf("."));
			var defaultIdBase:String = newFilename.slice(0, newFilename.lastIndexOf("."));
			while (defaultIdBase.indexOf("-") > 0) {
				defaultIdBase = defaultIdBase.replace("-", "");
			}
			var defaultId:String = defaultIdBase;
			var num:int = 1;
			while (catalog.entry(defaultId) != null) {
				defaultId = defaultIdBase + String(num++);
			}
			var options:Object = { buttons:["OK", "Cancel"], inputs:["id:"], restricts:["A-Za-z0-9_"], defaultValues:[defaultId],
					callback:callback };
			var text:String = "Enter catalog id for " + idForWhat;
			if (previousError != null) {
				text = previousError + "\n" + text;
			}
			KludgeDialogBox.show(text, options);
		}
		
		private function userEnteredNameForNewTileset(buttonClicked:String, values:Array):void {
			if (buttonClicked != "OK") {
				return;
			}
			if (!catalog.addCatalogEntry(values[0], newFilename, null, CatalogEntry.TILESET, new MessageCollector())) {
				launchIdDialog("tileset", userEnteredNameForNewTileset, "Error -- id '" + values[0] + "' already in use.");
				return;
			}
			tilesetId = values[0];
			
			var tileset:Tileset = catalog.retrieveTileset(tilesetId);
			tileset.createDefaultTileNames();
			
			var xml:XML = tileset.renderAsXml(tilesetId);
			catalog.appendXml(xml);
			displayTilesForEditNames();
		}
		
		private function userEnteredNameForNewChar(buttonClicked:String, values:Array):void {
			if (buttonClicked != "OK") {
				return;
			}
			
			var id:String = values[0];
			var entry:CatalogEntry = catalog.addCatalogEntry(id, newFilename, null, CatalogEntry.CHARACTER, new MessageCollector());
			
			if (entry == null) {
				launchIdDialog("character", userEnteredNameForNewChar, "Error -- id '" + id + "' already in use.");
				return;
			}
			
			var xml:XML = <char/>;
			xml.@file = newFilename;
			xml.@id = id;
			xml.@animate = "unknown";
			catalog.appendXml(xml);
			entry.xml = xml;
			
			showEditCharDialog(id);
		}
		
		private function userEnteredNameForNewProp(buttonClicked:String, values:Array):void {
			if (buttonClicked != "OK") {
				return;
			}
			
			var id:String = values[0];
			var entry:CatalogEntry = catalog.addCatalogEntry(id, newFilename, null, CatalogEntry.PROP, new MessageCollector());
			
			if (entry == null) {
				launchIdDialog("prop", userEnteredNameForNewProp, "Error -- id '" + id + "' already in use.");
				return;
			}
			
			var xml:XML = <prop/>;
			xml.@file = newFilename;
			xml.@id = id;
			catalog.appendXml(xml);
			entry.xml = xml;
			
			showEditPropDialog(id);
		}
		
		private function userEnteredNameForNewWeapon(buttonClicked:String, values:Array):void {
			if (buttonClicked != "OK") {
				return;
			}
			
			var id:String = values[0];
			var entry:CatalogEntry = catalog.addCatalogEntry(id, newFilename, null, CatalogEntry.WEAPON, new MessageCollector());
			
			if (entry == null) {
				launchIdDialog("weapon", userEnteredNameForNewWeapon, "Error -- id '" + id + "' already in use.");
				return;
			}
			
			var xml:XML = <weapon/>;
			xml.@id = id;
			catalog.appendXml(xml);
			entry.xml = xml;
			
			showEditWeaponDialog(id);
		}
		
		private function userEnteredNameForNewSplash(buttonClicked:String, values:Array):void {
			if (buttonClicked != "OK") {
				return;
			}
			
			var id:String = values[0];
			var entry:CatalogEntry = catalog.addCatalogEntry(id, newFilename, null, CatalogEntry.SPLASH, new MessageCollector());
			
			if (entry == null) {
				launchIdDialog("splash", userEnteredNameForNewProp, "Error -- id '" + id + "' already in use.");
				return;
			}
			
			var xml:XML = <splash/>;
			xml.@file = newFilename;
			xml.@id = id;
			catalog.appendXml(xml);
			entry.xml = xml;
			
			showEditSplashDialog(id);
		}
		
		private var tilesetCombo:ComboBox;
		private function clickedEditTileNames(event:Event):void {
			var tilesetChooser:ComboHolder = catalog.createChooser(CatalogEntry.TILESET);
			tilesetCombo = tilesetChooser.comboBox;

			var options:Object = { buttons:["OK", "Cancel"], inputs:[], customControl:tilesetChooser,
					callback:selectTilesetCallback };
			var text:String = "Select tileset:";
			KludgeDialogBox.show(text, options);
			
		}
		private function selectTilesetCallback(buttonClicked:String, values:Array):void {
			if (buttonClicked != "OK") {
				return;
			}
			tilesetId = tilesetCombo.value;
			tilesetCombo = null;
			displayTilesForEditNames();
		}
		
		private function displayTilesForEditNames():void {
			if (tilesPalette != null) {
				removeChild(tilesPalette);
			}
			tilesPalette = new FloorTilePalette(catalog);
			tilesPalette.setEditMode(true, tilesetId);
			tilesPalette.x = 5;
			tilesPalette.y = 60;
			addChild(tilesPalette);
			finishedEditNamesButton.x = tilesPalette.x + tilesPalette.width + 10;
			finishedEditNamesButton.y = tilesPalette.y;
			finishedEditNamesButton.visible = true;
			deleteTilesetButton.x = tilesPalette.x + tilesPalette.width + 10;
			deleteTilesetButton.y = tilesPalette.y + 30;
			deleteTilesetButton.visible = true;
		}
		
		private function clickedEditProp(event:Event):void {
			showEditPropDialog();
		}
		
		private function showEditPropDialog(id:String = null):void {
			var options:Object = { buttons:["Done"], inputs:[], customControl:new PropEditUI(catalog, id) };
			var text:String = "Edit prop";
			KludgeDialogBox.show(text, options);
		}
		
		private function clickedEditChar(event:Event):void {
			showEditCharDialog();
		}
		
		private function showEditCharDialog(id:String = null):void {
			var options:Object = { buttons:["Done"], inputs:[], customControl:new CharEditUI(catalog, id) };
			var text:String = "Edit Character";
			KludgeDialogBox.show(text, options);
		}
		
		private function clickedEditWeapon(event:Event):void {
			showEditWeaponDialog();
		}
		
		private function showEditWeaponDialog(id:String = null):void {
			var options:Object = { buttons:["Done"], inputs:[], customControl:new WeaponEditUI(catalog, id) };
			var text:String = "Edit Weapon";
			KludgeDialogBox.show(text, options);
		}
		
		private function clickedEditSplash(event:Event):void {
			showEditSplashDialog();
		}
		
		private function showEditSplashDialog(id:String = null):void {
			var options:Object = { buttons:["Done"], inputs:[], customControl:new SplashEditUi(catalog, id) };
			var text:String = "Edit Splash";
			KludgeDialogBox.show(text, options);
		}
		
		private function clickedSaveCatalog(event:Event):void {
			catalog.save();
		}
		
		private function clickedEditNamesDone(event:Event):void {
			tilesPalette.setTileNamesFromPalette();
			catalog.changeXml(tilesetId, catalog.retrieveTileset(tilesetId).renderAsXml(tilesetId));
			closeTilesPalette();
		}
		
		private function closeTilesPalette():void {
			removeChild(tilesPalette);
			tilesPalette = null;
			finishedEditNamesButton.visible = false;
			deleteTilesetButton.visible = false;
		}
		
		private function clickedDeleteTileset(event:Event):void {
			confirmDelete(deleteTilesetCallback);
		}
		
		private function deleteTilesetCallback(buttonClicked:String):void {
			if (buttonClicked != "Delete") {
				return;
			}
			catalog.deleteCatalogEntry(tilesetId);
			closeTilesPalette();
			warnSaveCatalogAndRestart();
		}

		private function clickedEditRoom(event:Event):void {
			(parent as Main).editRoom();
		}
		
		public static function confirmDelete(callback:Function):void {
			var options:Object = { buttons:["Delete", "OMG no!"], callback:callback };
			Alert.show("Do you really want to delete it, or\ndid you just click that big red button\nbecause it was so pretty and shiny)?", options);
		}
		
		public static function warnSaveCatalogAndRestart():void {
			Alert.show("Warning! You should save the catalog and\nrestart before editing rooms,\nor Things May Go Wrong.");
		}
		
	}

}