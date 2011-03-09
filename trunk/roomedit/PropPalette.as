package angel.roomedit {
	import angel.common.Alert;
	import angel.common.Catalog;
	import angel.common.FloorTile;
	import angel.common.KludgeDialogBox;
	import angel.common.Prop;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class PropPalette extends Sprite implements IRoomEditorPalette {

		private var catalog:CatalogEdit;
		private var room:RoomLight;
		
		private var selectedPropName:String = "";
		private var selectedPropBitmapData:BitmapData;
		private var selection:Sprite = null;
		private var propImagesToLoad:int;
		private var imagesAcross:int = 3;
		
		public function PropPalette(room:RoomLight, catalog:CatalogEdit) {
			this.room = room;
			this.catalog = catalog;

			var allPropNames:Array = catalog.allPropNames();
			propImagesToLoad = allPropNames.length;
			
			while (imagesAcross * imagesAcross < allPropNames.length) {
				imagesAcross += 3;
			}
			this.scaleX = this.scaleY = 3 / imagesAcross;
			
			graphics.lineStyle(2, 0x000000);
			graphics.beginFill(FloorTilePalette.BACKCOLOR, 1);
			graphics.drawRect(0, 0, imagesAcross*Prop.WIDTH, imagesAcross*Prop.HEIGHT);
			
			for (var i:int = 0; i < allPropNames.length; i++) {
				addPaletteItem(i, allPropNames[i]);
			}
			
		}

		private function addPaletteItem(i:int, propName:String):void {
			var sprite:Sprite = new Sprite();
			sprite.name = propName;
			addChild(sprite);
			sprite.x = (i % imagesAcross) * Prop.WIDTH;
			sprite.y = Math.floor(i / imagesAcross) * Prop.HEIGHT;			
			catalog.retrieveBitmapData(propName, function(bitmapData:BitmapData):void {
				var bitmap:Bitmap = new Bitmap(bitmapData);
				sprite.addChild(bitmap);
				--propImagesToLoad;
				if (propImagesToLoad == 0) {
					addEventListener(MouseEvent.CLICK, clickListener);
				}
			});
		}
		
		public function applyToTile(floorTile:FloorTile):void {
			if (room.occupied(floorTile.location)) {
				room.removeProp(floorTile.location);
			} else if (selectedPropName != "") {
				var prop:Prop = new Prop(new Bitmap(selectedPropBitmapData));
				room.addProp(prop, selectedPropName, floorTile.location);
			}
		}
		
		private function moveHilight(newSelection:Sprite):void {
			if (selection != null) {
				selection.graphics.beginFill(FloorTilePalette.BACKCOLOR, 1);
				selection.graphics.drawRect(0, 0, Prop.WIDTH, Prop.HEIGHT);
			}
			selection = newSelection;
			if (newSelection != null) {
				selection.graphics.beginFill(FloorTilePalette.SELECT_COLOR, 1);
				selection.graphics.drawRect(0, 0, Prop.WIDTH, Prop.HEIGHT);
			}
		}	

		private function clickListener(event:MouseEvent):void {
			if (event.target != this) {
				var foo:Sprite = (event.target as Sprite);
				selectedPropName = foo.name;
				selectedPropBitmapData = Bitmap(foo.getChildAt(0)).bitmapData;
				moveHilight(foo);
			}
		}
		
		// Puts up dialog for user to select prop name
		public function launchPropDialog():void {
			if (!catalog.loaded) {
				Alert.show("Catalog not loaded yet");
				return;
			}
			KludgeDialogBox.init(stage);
			var options:Object = new Object();
			options.buttons = ["OK", "Cancel"];
			options.inputs = ["Prop name:"];
			options.callback = userEnteredPropName;
			KludgeDialogBox.show("Select prop name to place:", options);
		}

		private function userEnteredPropName(buttonClicked:String, values:Array):void {
			if (buttonClicked != "OK") {
				return;
			}
			catalog.retrieveBitmapData(values[0], function(bitmapData:BitmapData):void {
				selectedPropName = values[0];
				selectedPropBitmapData = bitmapData;
				var foo:Bitmap = new Bitmap(bitmapData);
				foo.x = 100;
				foo.y = 100;
				addChild(foo);
			});
			
		}
			
	
		
	} // end class PropPalette

}
