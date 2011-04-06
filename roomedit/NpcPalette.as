package angel.roomedit {
	import angel.common.Alert;
	import angel.common.CatalogEntry;
	import angel.common.Prop;
	import angel.common.Util;
	import angel.common.WalkerImage;
	import fl.controls.ComboBox;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class NpcPalette extends Sprite implements IRoomEditorPalette {
		private var catalog:CatalogEdit;
		private var room:RoomLight;
		private var walkerFacingFront:Bitmap;
		private var walkerCombo:ComboBox;
		private var locationText:TextField;
		private var attributeDisplay:Sprite;
		private var exploreCombo:ComboBox;
		private var combatCombo:ComboBox;
		
		private var locationOfCurrentSelection:Point;
		
		private static const exploreChoices:Vector.<String> = Vector.<String>(["", "fidget", "wander"]);
		private static const combatChoices:Vector.<String> = Vector.<String>(["", "wander"]);
		
		public function NpcPalette(catalog:CatalogEdit, room:RoomLight) {
			this.catalog = catalog;
			this.room = room;
			
			graphics.beginFill(EditorSettings.PALETTE_BACKCOLOR, 1);
			graphics.drawRect(0, 0, EditorSettings.PALETTE_XSIZE, EditorSettings.PALETTE_YSIZE);
			
			walkerFacingFront = new Bitmap(new BitmapData(Prop.WIDTH, Prop.HEIGHT));
			walkerFacingFront.x = (this.width - walkerFacingFront.width) / 2;
			walkerFacingFront.y = 10;
			addChild(walkerFacingFront);
			
			var walkerChooser:Sprite = catalog.createChooser(CatalogEntry.WALKER, EditorSettings.PALETTE_XSIZE - 10);
			walkerChooser.x = (this.width - walkerChooser.width) / 2;
			walkerChooser.y = Prop.HEIGHT + 20;
			addChild(walkerChooser);
			walkerCombo = ComboBox(walkerChooser.getChildAt(0));
			walkerCombo.addEventListener(Event.CHANGE, changeWalker);
			
			locationText = Util.textBox("", EditorSettings.PALETTE_XSIZE, Util.DEFAULT_TEXT_HEIGHT, TextFormatAlign.CENTER);
			locationText.y = walkerChooser.y + walkerCombo.height + 10;
			addChild(locationText);
			
			attributeDisplay = createAttributeDisplay();
			attributeDisplay.x = walkerChooser.x;
			attributeDisplay.y = locationText.y + locationText.height + 10;
			addChild(attributeDisplay);
			
			walkerCombo.selectedIndex = 0;
			changeWalker(null);
			
			room.addEventListener(Event.INIT, roomLoaded);
		}
		
		private function createAttributeDisplay():Sprite {
			var holder:Sprite = new Sprite();
			
			var exploreLabel:TextField = Util.textBox("Explore mode behavior:", EditorSettings.PALETTE_XSIZE-20);
			holder.addChild(exploreLabel);
			exploreCombo = createBrainChooser(exploreChoices);
			exploreCombo.y = exploreLabel.y + exploreLabel.height;
			exploreCombo.addEventListener(Event.CHANGE, changeExplore);
			holder.addChild(exploreCombo);
			
			var combatLabel:TextField = Util.textBox("Combat mode behavior:", EditorSettings.PALETTE_XSIZE-20);
			combatLabel.y = exploreCombo.y + exploreCombo.height + 10;
			holder.addChild(combatLabel);
			combatCombo = createBrainChooser(combatChoices);
			combatCombo.y = combatLabel.y + combatLabel.height;
			combatCombo.addEventListener(Event.CHANGE, changeCombat);
			holder.addChild(combatCombo);
			
			return holder;
		}
		
		
		private function changeWalker(event:Event):void {
			var walkerId:String = walkerCombo.selectedLabel;
			
			var walkerImage:WalkerImage = catalog.retrieveWalkerImage(walkerId);
			walkerFacingFront.bitmapData = walkerImage.bitsFacing(1);
			
			updateAvailabilityAndAttributes();
		}
		
		private function updateAvailabilityAndAttributes():void {
			locationOfCurrentSelection = room.find(walkerCombo.selectedLabel);
			var onMap:Boolean = (locationOfCurrentSelection != null);
			locationText.text = (onMap ? "Location: " + locationOfCurrentSelection : "Available");
			attributeDisplay.visible = onMap;
			
			if (onMap) {
				var attributes:Object = room.attributesOfItemAt(locationOfCurrentSelection);
				if (attributes == null) {
					exploreCombo.selectedIndex = 0;
					combatCombo.selectedIndex = 0;
				} else {
					exploreCombo.selectedIndex = indexInChoices(exploreChoices, attributes["explore"]);
					combatCombo.selectedIndex = indexInChoices(combatChoices, attributes["combat"]);
				}
			}
		}
		
		private function changeExplore(event:Event):void {
			var attributes:Object = room.attributesOfItemAt(locationOfCurrentSelection);
			if (attributes == null) {
				attributes = new Object();
			}
			attributes["explore"] = exploreCombo.selectedLabel;
			room.setAttributesOfItemAt(locationOfCurrentSelection, attributes);
		}
		
		private function changeCombat(event:Event):void {
			var attributes:Object = room.attributesOfItemAt(locationOfCurrentSelection);
			if (attributes == null) {
				attributes = new Object();
			}
			attributes["combat"] = combatCombo.selectedLabel;
			room.setAttributesOfItemAt(locationOfCurrentSelection, attributes);
		}

		public function applyToTile(tile:FloorTileEdit):void {
			if (room.occupied(tile.location)) {
				room.removeItemAt(tile.location);
			} else {
				if (locationOfCurrentSelection == null) {
					//CONSIDER: this will need revision if we add resource management
					var prop:Prop = Prop.createFromBitmapData(walkerFacingFront.bitmapData);
					room.addContentItem(prop, CatalogEntry.WALKER, walkerCombo.selectedLabel, tile.location);
				} else {
					Alert.show("Cannot place " + walkerCombo.selectedLabel + " -- already in room.");
				}
			}
			updateAvailabilityAndAttributes();
		}
		
		public function paintWhileDragging():Boolean {
			return false;
		}
		
		private function roomLoaded(event:Event):void {
			if (this.visible) {
				updateAvailabilityAndAttributes();
			}
		}
		
		// Whenever we become visible, update the walker location text
		override public function set visible(value:Boolean):void {
			super.visible = value;
			if (this.visible) {
				updateAvailabilityAndAttributes();
			}
		}
		
		private function createBrainChooser(choices:Vector.<String>):ComboBox {
			var combo:ComboBox = new ComboBox();
			combo.width = EditorSettings.PALETTE_XSIZE - 10;
			for (var i:int = 0; i < choices.length; i++) {
				combo.addItem( { label:choices[i] } );
			}
			return combo;
		}
		
		private function indexInChoices(choices:Vector.<String>, label:String):int {
			for (var i:int = 0; i < choices.length; i++) {
				if (choices[i] == label) {
					return i;
				}
			}
			return 0;
		}
		
	} // end class NpcPalette

}