package angel.game {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Icon {
		
		public function Icon() {
			
		}
		public static function bitmapData(cl:Class):BitmapData {
			return new cl().bitmapData;
		}
		
				
		[Embed(source='../../../EmbeddedAssets/TestMenuItem.png')]
		public static const TestIconBitmap:Class;
		
		[Embed(source = '../../../EmbeddedAssets/IconCancelMove.png')]
		public static const CancelMove:Class;
		[Embed(source = '../../../EmbeddedAssets/IconStay.png')]
		public static const Stay:Class;
		[Embed(source = '../../../EmbeddedAssets/IconWalk.png')]
		public static const Walk:Class;
		[Embed(source = '../../../EmbeddedAssets/IconRun.png')]
		public static const Run:Class;
		[Embed(source = '../../../EmbeddedAssets/IconSprint.png')]
		public static const Sprint:Class;
		
		[Embed(source = '../../../EmbeddedAssets/combat_icon_fire.png')]
		public static const CombatFire:Class;
		[Embed(source='../../../EmbeddedAssets/combat_icon_cancel.png')]
		public static const CombatCancelTarget:Class;
		[Embed(source = '../../../EmbeddedAssets/combat_icon_hold.png')]
		public static const CombatReserveFire:Class;
		[Embed(source='../../../EmbeddedAssets/combat_icon_cover.png')]
		public static const CombatFireFromCover:Class;
		[Embed(source = '../../../EmbeddedAssets/combat_icon_notarget.png')]
		public static const CombatNoTarget:Class;
		
		[Embed(source = '../../../EmbeddedAssets/combat_cursor_active.png')]
		public static const CombatCursorActive:Class;
		[Embed(source = '../../../EmbeddedAssets/combat_cursor_inactive.png')]
		public static const CombatCursorInactive:Class;
		
		[Embed(source='../../../EmbeddedAssets/ReserveFire.png')]
		public static const ReserveFireFloater:Class;
		
	}

}