package angel.roomedit {
	import fl.controls.ComboBox;
	import flash.display.Sprite;
	
	// WARNING: ComboBox violates all sorts of groundrules.  It changes parent's height to MORE than its
	// own height property.  Also, if its width is increased it sticks out past the edge of its parent
	// without changing parent's width.
	// The best workaround I've found for this is to enclose it in a sprite (which fixes the height
	// problem) and draw an invisible line across the correct width.
	public class ComboHolder extends Sprite {
		
		public function ComboHolder(width:int, combo:ComboBox) {
			graphics.moveTo(0, 0);
			graphics.lineTo(width, 0);
			addChild(combo);
		}

		public function get comboBox():ComboBox {
			return ComboBox(getChildAt(0));
		}
		
		public override function get height():Number {
			return getChildAt(0).height;
		}
	}
}