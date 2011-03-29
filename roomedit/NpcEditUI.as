package angel.roomedit {
	import angel.common.CatalogEntry;
	import angel.common.Prop;
	import angel.common.PropImage;
	import angel.common.Util;
	import angel.common.WalkerImage;
	import fl.controls.CheckBox;
	import fl.controls.ComboBox;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class NpcEditUI extends Sprite {

		private var catalog:CatalogEdit;
		private var propBitmap:Bitmap;
		private var propCombo:ComboBox;
		private var healthTextField:TextField;
		
		private static const WIDTH:int = 220;
		
		public function NpcEditUI(catalog:CatalogEdit) {
			this.catalog = catalog;
			
			propBitmap = new Bitmap(new BitmapData(Prop.WIDTH, Prop.HEIGHT));
			propBitmap.x = (WIDTH - Prop.WIDTH) / 2;
			addChild(propBitmap);
			
			var propChooser:Sprite = catalog.createChooser(CatalogEntry.WALKER, WIDTH);
			propCombo = ComboBox(propChooser.getChildAt(0));
			propCombo.addEventListener(Event.CHANGE, changeProp);
			propChooser.y = propBitmap.y + propBitmap.height + 10;
			addChild(propChooser);
			
			var label:TextField = Util.textBox("Health:", 50, 20);
			label.y = propChooser.y + propCombo.height + 10;
			addChild(label);
			healthTextField = Util.textBox("", 40, 20, TextFormatAlign.LEFT, true);
			healthTextField.x = label.x + label.width + 5;
			healthTextField.y = label.y;
			healthTextField.addEventListener(Event.CHANGE, changeHealth);
			addChild(healthTextField);

			propCombo.selectedIndex = 0;
			changeProp(null);
		}
		
		private function changeProp(event:Event):void {
			var walkerId:String = propCombo.selectedLabel;
			
			var walkerImage:WalkerImage = catalog.retrieveWalkerImage(walkerId);
			propBitmap.bitmapData = walkerImage.bitsFacing(WalkerImage.FACE_CAMERA);
			
			healthTextField.text = String(walkerImage.health);
		}
		
		private function changeHealth(event:Event):void {
			var walkerId:String = propCombo.selectedLabel;
			var walkerImage:WalkerImage = catalog.retrieveWalkerImage(walkerId);
			
			walkerImage.health = int(healthTextField.text);
			catalog.changeXmlAttribute(walkerId, "health", String(walkerImage.health));
		}
		
	} // end class PropEditUI

}