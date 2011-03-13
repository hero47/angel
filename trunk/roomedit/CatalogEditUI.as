package angel.roomedit {
	import angel.common.Alert;
	import angel.common.CatalogEntry;
	import angel.common.KludgeDialogBox;
	import angel.common.SimplerButton;
	import angel.common.Tileset;
	import fl.controls.ComboBox;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CatalogEditUI extends Sprite {
		
		private var catalog:CatalogEdit;
		public var tilesPalette:FloorTilePalette;
		
		private var finishedEditNamesButton:SimplerButton;
		
		private var newTilesetFilename:String;
		private var tilesetId:String;
		
		public function CatalogEditUI(catalog:CatalogEdit) {
			this.catalog = catalog;
			
			var button:SimplerButton;
			var left:int = 10;
			
			button = new SimplerButton("Add tileset", clickedLoadTileset);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 5;
			
			button = new SimplerButton("Edit tile names", clickedEditTileNames);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 5;
			
			button = new SimplerButton("Save Catalog", clickedSaveCatalog);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 5;
			
			button = new SimplerButton("Edit Room", clickedEditRoom);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 5;
			
			
			finishedEditNamesButton = new SimplerButton("Keep these names", clickedEditNamesDone, 0xff0000);
			finishedEditNamesButton.width = 200;
			addChild(finishedEditNamesButton);
			finishedEditNamesButton.visible = false;
			
			
		}
		
		private function clickedLoadTileset(event:Event):void {
			new FileChooser(userSelectedNewTilesetFile, null, false);
		}
		
		private function userSelectedNewTilesetFile(filename:String):void {
			newTilesetFilename = filename;
			launchTilesetIdDialog();
		}
		
		public function launchTilesetIdDialog(previousError:String = null):void {
			//var filename:String = newlyLoadedTileset.catalogEntry.filename;
			//var defaultIdBase:String = filename.slice(0, filename.lastIndexOf("."));
			var defaultIdBase:String = newTilesetFilename.slice(0, newTilesetFilename.lastIndexOf("."));
			var defaultId:String = defaultIdBase;
			var num:int = 1;
			while (catalog.entry(defaultId) != null) {
				defaultId = defaultIdBase + String(num++);
			}
			KludgeDialogBox.init(stage);
			var options:Object = new Object();
			options.buttons = ["OK", "Cancel"];
			options.inputs = ["id:"];
			options.defaultValues = [defaultId];
			options.callback = userEnteredNameForNewTileset;
			var text:String = "Enter catalog id for tileset";
			if (previousError != null) {
				text = previousError + "\n" + text;
			}
			KludgeDialogBox.show(text, options);
		}
		
		private function userEnteredNameForNewTileset(buttonClicked:String, values:Array):void {
			if (buttonClicked != "OK") {
				return;
			}
			if (!catalog.addCatalogEntry(values[0], newTilesetFilename, CatalogEntry.TILESET)) {
				launchTilesetIdDialog("Error -- id '" + values[0] + "' already in use.");
				return;
			}
			tilesetId = values[0];
			
			var tileset:Tileset = catalog.retrieveTileset(tilesetId);
			tileset.createDefaultTileNames();
			
			var xml:XML = tileset.renderAsXml(tilesetId);
			catalog.appendXml(xml);
			displayTilesForEditNames();
		}
		
		private var tilesetCombo:ComboBox;
		private function clickedEditTileNames(event:Event):void {
			var tilesetChooser:Sprite = catalog.createChooser(CatalogEntry.TILESET);
			tilesetCombo = ComboBox(tilesetChooser.getChildAt(0));

			KludgeDialogBox.init(stage);
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
			tilesPalette = new FloorTilePalette(catalog, tilesetId, true);
			tilesPalette.x = 5;
			tilesPalette.y = 30;
			addChild(tilesPalette);
			finishedEditNamesButton.x = tilesPalette.x + tilesPalette.width + 10;
			finishedEditNamesButton.y = tilesPalette.y;
			finishedEditNamesButton.visible = true;
		}
		
		private function clickedSaveCatalog(event:Event):void {
			catalog.save();
		}
		
		private function clickedEditNamesDone(event:Event):void {
			tilesPalette.setTileNamesFromPalette();
			removeChild(tilesPalette);
			tilesPalette = null;
			finishedEditNamesButton.visible = false;
			catalog.changeXml(tilesetId, catalog.retrieveTileset(tilesetId).renderAsXml(tilesetId));
		}

		private function clickedEditRoom(event:Event):void {
			(parent as Main).editRoom();
		}
		
	}

}