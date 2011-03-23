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
		
	}

}