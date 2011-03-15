package angel.roomedit {
	import angel.common.Tileset;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class EditorSettings {
		public static const PALETTE_BACKCOLOR:uint = 0xffffff;
		public static const PALETTE_SELECT_COLOR:uint = 0x00ffff;
		
		public static const PALETTE_LABEL_WIDTH:int = Tileset.TILE_WIDTH;
		public static const PALETTE_LABEL_HEIGHT:int = 20;
		
		public static const X_GUTTER:int = 1;
		public static const Y_GUTTER:int = 5;
		public static const TILE_ITEM_HEIGHT:int = (Tileset.TILE_HEIGHT + PALETTE_LABEL_HEIGHT + Y_GUTTER);
		public static const TILE_ITEM_WIDTH:int = Tileset.TILE_WIDTH + X_GUTTER;
		public static const PALETTE_XSIZE:int = Tileset.TILE_WIDTH * 3;
		public static const PALETTE_YSIZE:int = 7 * TILE_ITEM_HEIGHT;
		
		public function EditorSettings() {
			
		}
		
	}

}