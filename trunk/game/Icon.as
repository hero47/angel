package angel.game {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Icon {
		
		public static const STANDARD_ICON_SIZE:int = 28;
		public static const ICON_SIZED_POINT:Point = new Point(STANDARD_ICON_SIZE, STANDARD_ICON_SIZE);
		public static const ICON_SIZED_RECTANGLE:Rectangle = new Rectangle(0, 0, STANDARD_ICON_SIZE, STANDARD_ICON_SIZE);
		public static const ZEROZERO:Point = new Point(0, 0);
		
		public function Icon() {
			
		}
		public static function bitmapData(cl:Class):BitmapData {
			return new cl().bitmapData;
		}
		
		public static function copyIconData(cl:Class, dest:BitmapData):void {
			dest.copyPixels(new cl().bitmapData, ICON_SIZED_RECTANGLE, ZEROZERO);
		}
		
				
		[Embed(source='../EmbeddedAssets/TestMenuItem.png')]
		public static const TestIconBitmap:Class;
		
		// Combat move pie menu icons
		[Embed(source = '../EmbeddedAssets/IconCancelMove.png')]
		public static const CancelMove:Class;
		[Embed(source = '../EmbeddedAssets/IconStay.png')]
		public static const Stay:Class;
		[Embed(source = '../EmbeddedAssets/IconWalk.png')]
		public static const Walk:Class;
		[Embed(source = '../EmbeddedAssets/IconRun.png')]
		public static const Run:Class;
		[Embed(source = '../EmbeddedAssets/IconSprint.png')]
		public static const Sprint:Class;
		[Embed(source='../EmbeddedAssets/combat_icon_cover.png')]
		public static const CombatFireFromCover:Class;
		
		// Combat fire pie menu icons
		[Embed(source = '../EmbeddedAssets/combat_icon_fire.png')]
		public static const DefaultHandWeaponIcon:Class;
		[Embed(source='../EmbeddedAssets/combat_icon_grenade.png')]
		public static const DefaultThrownWeaponIcon:Class;
		[Embed(source = '../EmbeddedAssets/combat_icon_pass.png')]
		public static const CombatPass:Class;
		[Embed(source='../EmbeddedAssets/combat_icon_items.png')]
		public static const CombatOpenItemMenu:Class;
		
		[Embed(source = '../EmbeddedAssets/combat_icon_newpoint.png')]
		public static const CombatAddWaypoint:Class;
		
		// Explore pie menu
		[Embed(source = '../EmbeddedAssets/combat_icon_revive.png')]
		public static const Revive:Class;
		
		// Combat cursor
		[Embed(source = '../EmbeddedAssets/combat_cursor_active.png')]
		public static const CombatCursorActive:Class;
		
		// Displayed in combat instead of weapon fire
		[Embed(source='../EmbeddedAssets/ReserveFire.png')]
		public static const ReserveFireFloater:Class;
		[Embed(source='../EmbeddedAssets/NoGun.png')]
		public static const NoGunFloater:Class;
		
		
		// Inventory assets
		
		[Embed(source = '../EmbeddedAssets/inventory_background.png')]
		public static const InventoryBackground:Class;
		[Embed(source = '../EmbeddedAssets/inventory_main_hand.png')]
		public static const InventoryMainHand:Class;
		[Embed(source='../EmbeddedAssets/inventory_off_hand.png')]
		public static const InventoryOffHand:Class;
	}

}