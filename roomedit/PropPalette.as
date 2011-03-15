package angel.roomedit {
	import angel.common.Alert;
	import angel.common.Catalog;
	import angel.common.CatalogEntry;
	import angel.common.FloorTile;
	import angel.common.KludgeDialogBox;
	import angel.common.Prop;
	import angel.common.PropImage;
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
		
		public function PropPalette(catalog:CatalogEdit, room:RoomLight) {
			this.room = room;
			this.catalog = catalog;

			var allPropNames:Array = catalog.allNames(CatalogEntry.PROP);
		
			var imagesAcross:int = 3;
			while (imagesAcross * imagesAcross < allPropNames.length) {
				imagesAcross += 3;
			}
			this.scaleX = this.scaleY = 3 / imagesAcross;
			
			graphics.beginFill(EditorSettings.PALETTE_BACKCOLOR, 1);
			graphics.drawRect(0, 0, imagesAcross*Prop.WIDTH, imagesAcross*Prop.HEIGHT);
			
			for (var i:int = 0; i < allPropNames.length; i++) {
				addPaletteItem(allPropNames[i], i, imagesAcross);
			}
			
			addEventListener(MouseEvent.CLICK, clickListener);
		}

		private function addPaletteItem(propName:String, i:int, imagesAcross:int):void {
			var sprite:Sprite = new Sprite();
			sprite.name = propName;
			addChild(sprite);
			sprite.x = (i % imagesAcross) * Prop.WIDTH;
			sprite.y = Math.floor(i / imagesAcross) * Prop.HEIGHT;
			var propImage:PropImage = catalog.retrievePropImage(propName);
			var bitmap:Bitmap = new Bitmap(propImage.imageData);
			sprite.addChild(bitmap);
		}
		
		public function applyToTile(floorTile:FloorTileEdit):void {
			if (room.occupied(floorTile.location)) {
				room.removeItemAt(floorTile.location);
			} else if (selectedPropName != "") {
				//CONSIDER: this will need revision if we add resource management
				var prop:Prop = Prop.createFromBitmapData(selectedPropBitmapData);
				room.addContentItem(prop, CatalogEntry.PROP, selectedPropName, floorTile.location);
			}
		}
		
		public function paintWhileDragging():Boolean {
			return false;
		}
		
		private function moveHilight(newSelection:Sprite):void {
			if (selection != null) {
				selection.graphics.beginFill(EditorSettings.PALETTE_BACKCOLOR, 1);
				selection.graphics.drawRect(0, 0, Prop.WIDTH, Prop.HEIGHT);
			}
			selection = newSelection;
			if (newSelection != null) {
				selection.graphics.beginFill(EditorSettings.PALETTE_SELECT_COLOR, 1);
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
		
	} // end class PropPalette

}
