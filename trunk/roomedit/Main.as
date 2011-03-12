package angel.roomedit {
	import angel.common.*;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class Main extends Sprite {

		
		private var catalog:CatalogEdit;
		private var roomUI:RoomEditUI;
		private var catalogUI:CatalogEditUI;
		
		public var tilesPalette:FloorTilePalette;
		public var propPalette:PropPalette;

		public function Main():void {
			Alert.init(stage);
			catalog = new CatalogEdit();
			catalog.addEventListener(Catalog.CATALOG_LOADED_EVENT, catalogLoadedListener);
			catalog.loadFromXmlFile("AngelCatalog.xml");
		}
		
		private function catalogLoadedListener(event:Event):void {
			catalog.removeEventListener(Catalog.CATALOG_LOADED_EVENT, catalogLoadedListener);
			roomUI = new RoomEditUI(catalog);
			addChild(roomUI);
			catalogUI = new CatalogEditUI(catalog);
			addChild(catalogUI);
			catalogUI.visible = false;
		}
		
		public function editRoom():void {
			roomUI.visible = true;
			catalogUI.visible = false;
		}
		
		public function editCatalog():void {
			roomUI.visible = false;
			catalogUI.visible = true;
		}
		
		/*
		private function changeTilesetCallback(newTileset:Tileset):void {
			floor.changeTileset(newTileset);
			tilesPalette.changeTileset(floor.tileset);
		}
		*/
		
	} // end class Main
	
}