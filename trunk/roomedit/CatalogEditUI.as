package angel.roomedit {
	import angel.common.Alert;
	import angel.common.CatalogEntry;
	import angel.common.KludgeDialogBox;
	import angel.common.SimplerButton;
	import angel.common.Tileset;
	import angel.common.WalkerImage;
	import fl.controls.ComboBox;
	import flash.display.BitmapData;
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
		
		private var newFilename:String;
		private var tilesetId:String;
		private var propId:String;
		
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
			left += button.width + 20;
			
			button = new SimplerButton("Add Prop", clickedAddProp);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 5;
			
			button = new SimplerButton("Edit props", clickedEditProp);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 20;
			
			button = new SimplerButton("Add NPC", clickedAddNpc);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 5;
			
			button = new SimplerButton("Edit NPCs", clickedEditNpc);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 20;
			
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
			newFilename = filename;
			launchIdDialog("tileset", userEnteredNameForNewTileset);
		}
		
		private function clickedAddNpc(event:Event):void {
			new FileChooser(userSelectedNewNpcFile, null, false);
		}
		
		private function userSelectedNewNpcFile(filename:String):void {
			newFilename = filename;
			launchIdDialog("NPC", userEnteredNameForNewNpc);
		}
		
		private function clickedAddProp(event:Event):void {
			new FileChooser(userSelectedNewPropFile, null, false);
		}
		
		private function userSelectedNewPropFile(filename:String):void {
			newFilename = filename;
			launchIdDialog("prop", userEnteredNameForNewProp);
		}
		
		public function launchIdDialog(idForWhat:String, callback:Function, previousError:String = null):void {
			//var filename:String = newlyLoadedTileset.catalogEntry.filename;
			//var defaultIdBase:String = filename.slice(0, filename.lastIndexOf("."));
			var defaultIdBase:String = newFilename.slice(0, newFilename.lastIndexOf("."));
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
			options.callback = callback;
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
			if (!catalog.addCatalogEntry(values[0], newFilename, CatalogEntry.TILESET)) {
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
		
		private function userEnteredNameForNewNpc(buttonClicked:String, values:Array):void {
			if (buttonClicked != "OK") {
				return;
			}
			
			var id:String = values[0];
			
			if (!catalog.addCatalogEntry(id, newFilename, CatalogEntry.WALKER)) {
				launchIdDialog("NPC", userEnteredNameForNewNpc, "Error -- id '" + id + "' already in use.");
				return;
			}
			
			var xml:XML = <walker/>;
			xml.@file = newFilename;
			xml.@id = id;
			catalog.appendXml(xml);
			
			showEditNpcDialog(id);
		}
		
		private function userEnteredNameForNewProp(buttonClicked:String, values:Array):void {
			if (buttonClicked != "OK") {
				return;
			}
			
			var id:String = values[0];
			
			if (!catalog.addCatalogEntry(id, newFilename, CatalogEntry.PROP)) {
				launchIdDialog("prop", userEnteredNameForNewNpc, "Error -- id '" + id + "' already in use.");
				return;
			}
			
			var xml:XML = <prop/>;
			xml.@file = newFilename;
			xml.@id = id;
			catalog.appendXml(xml);
			
			showEditPropDialog(id);
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
		
		private function clickedEditProp(event:Event):void {
			showEditPropDialog();
		}
		
		private function showEditPropDialog(id:String = null):void {
			KludgeDialogBox.init(stage);
			var options:Object = { buttons:["Done"], inputs:[], customControl:new PropEditUI(catalog, id) };
			var text:String = "Edit prop";
			KludgeDialogBox.show(text, options);
		}
		
		private function clickedEditNpc(event:Event):void {
			showEditNpcDialog();
		}
		
		private function showEditNpcDialog(id:String = null):void {
			KludgeDialogBox.init(stage);
			var options:Object = { buttons:["Done"], inputs:[], customControl:new NpcEditUI(catalog, id) };
			var text:String = "Edit NPC";
			KludgeDialogBox.show(text, options);
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