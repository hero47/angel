package angel.roomedit {
	import angel.common.CatalogEntry;
	import angel.common.CharacterStats;
	import angel.common.Defaults;
	import angel.common.Prop;
	import angel.common.RoomContentResource;
	import angel.common.SimplerButton;
	import angel.common.Util;
	import angel.common.WalkerAnimationData;
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
	public class CharEditUI extends Sprite {

		private var catalog:CatalogEdit;
		private var propBitmap:Bitmap;
		private var propCombo:ComboBox;
		private var healthTextField:TextField;
		private var damageTextField:TextField;
		private var movePointsTextField:TextField;
		private var nameTextField:TextField;
		private var changeImageControl:FilenameControl;
		
		private static const WIDTH:int = 220;
		
		public function CharEditUI(catalog:CatalogEdit, startId:String = null) {
			this.catalog = catalog;
			
			var imageX:int = (WIDTH - Prop.WIDTH) / 2;
			
			graphics.lineStyle(1, 0, 1);
			graphics.moveTo(imageX, 0);
			graphics.lineTo(imageX + Prop.WIDTH, 0);
			var topButton:SimplerButton = new SimplerButton("Top", setTopByPixelScan);
			topButton.width = 50;
			topButton.x = imageX + Prop.WIDTH + 5;
			addChild(topButton);
			var resetTopButton:SimplerButton = new SimplerButton("Reset Top", resetTop);
			resetTopButton.width = 70;
			resetTopButton.x = topButton.x;
			resetTopButton.y = Prop.HEIGHT - resetTopButton.height;
			addChild(resetTopButton);
			
			propBitmap = new Bitmap(new BitmapData(Prop.WIDTH, Prop.HEIGHT));
			propBitmap.x = imageX;
			propBitmap.y = 1;
			addChild(propBitmap);
			
			var propChooser:ComboHolder = catalog.createChooser(CatalogEntry.WALKER, WIDTH);
			propChooser.comboBox.addEventListener(Event.CHANGE, changeProp);
			propChooser.y = propBitmap.y + propBitmap.height + 10;
			propCombo = propChooser.comboBox;
			addChild(propChooser);
			
			nameTextField = Util.createTextEditControlBelow(propChooser, "Display Name", 100, 100,
					function(event:Event):void { changeCharacterProperty(event.target.text, "displayName", Defaults.DISPLAY_NAME) }, 0);
			healthTextField = Util.createTextEditControlBelow(nameTextField, "Hits", 100, 40,
					function(event:Event):void { changeCharacterProperty(int(event.target.text), "health", Defaults.HEALTH) }, 0);
			damageTextField = Util.createTextEditControlBelow(healthTextField, "Damage", 100, 40,
					function(event:Event):void { changeCharacterProperty(int(event.target.text), "damage", Defaults.DAMAGE) }, 0);
			movePointsTextField = Util.createTextEditControlBelow(damageTextField, "Move Points", 100, 40,
					function(event:Event):void { changeCharacterProperty(int(event.target.text), "movePoints", Defaults.MOVE_POINTS) }, 0 );
			changeImageControl = FilenameControl.createBelow(movePointsTextField, false, "Image", 0, 220,
					function(event:Event):void { 
							var walkerId:String = propCombo.selectedLabel;
							catalog.changeFilename(walkerId, changeImageControl.text);
					}, 0 );
			
			if (startId == null) {
				propCombo.selectedIndex = 0;
			} else {
				for (var i:int = 0; i < propCombo.length; i++) {
					if (propCombo.getItemAt(i).label == startId) {
						propCombo.selectedIndex = i;
						break;
					}
				}
			}
			
			changeProp(null);
		}
		
		private function changeProp(event:Event):void {
			var walkerId:String = propCombo.selectedLabel;

			var resource:RoomContentResource = catalog.retrieveCharacterResource(walkerId);
			propBitmap.bitmapData = resource.standardImage();
			
			var characterStats:CharacterStats = resource.characterStats;
			nameTextField.text = characterStats.displayName;
			healthTextField.text = String(characterStats.health);
			damageTextField.text = String(characterStats.damage);
			movePointsTextField.text = String(characterStats.movePoints);
			changeImageControl.text = catalog.getFilenameFromId(walkerId);
		}
		
		private function changeCharacterProperty(newValue:*, propertyName:String, defaultValue:* = null):void {
			var walkerId:String = propCombo.selectedLabel;
			var characterStats:CharacterStats = catalog.retrieveCharacterResource(walkerId).characterStats;
			
			characterStats[propertyName] = newValue;
			if (newValue == defaultValue) {
				catalog.deleteXmlAttribute(walkerId, propertyName);
			} else {
				catalog.changeXmlAttribute(walkerId, propertyName, String(newValue));
			}
		}

		private function setTopByPixelScan(event:Event):void {
			var walkerId:String = propCombo.selectedLabel;
			
			var resource:RoomContentResource = catalog.retrieveCharacterResource(walkerId);
			
			var blankRows:int = countBlankRowsAtTop(resource.standardImage());
			var newUnusedPixels:int = WalkerAnimationData(resource.animationData).increaseTop(blankRows);
			resource.characterStats.unusedPixelsAtTopOfCell = newUnusedPixels;
			
			catalog.changeXmlAttribute(walkerId, "top", String(newUnusedPixels));
		}
		
		private function countBlankRowsAtTop(bits:BitmapData):int {
			for (var y:int = 0; y < bits.rect.height; y++) {
				for (var x:int = 0; x < bits.rect.width; x++) {
					if (bits.getPixel32(x, y) != 0) {
						return y;
					}
				}
			}
			return 0;
		}
		
		private function resetTop(event:Event):void {
			var walkerId:String = propCombo.selectedLabel;
			catalog.deleteXmlAttribute(walkerId, "top");
			catalog.discardCachedData(walkerId);
			changeProp(null);
		}
		
		private function changeImage(event:Event):void {
			new FileChooser(userSelectedNewCharFile, null, false);
		}
		
		private function userSelectedNewCharFile(filename:String):void {
			var walkerId:String = propCombo.selectedLabel;
			catalog.changeFilename(walkerId, filename);
		}
		
		
	} // end class PropEditUI

}