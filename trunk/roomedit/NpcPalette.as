package angel.roomedit {
	import angel.common.Alert;
	import angel.common.CatalogEntry;
	import angel.common.Prop;
	import angel.common.SimplerButton;
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
		private var talkFile:FilenameControl;
		private var removeButton:SimplerButton;
		
		private var currentSelection:Prop;
		private var locationOfCurrentSelection:Point;
		
		private static const exploreChoices:Vector.<String> = Vector.<String>(["", "fidget", "wander"]);
		private static const combatChoices:Vector.<String> = Vector.<String>(["", "wander"]);
		
		public function NpcPalette(catalog:CatalogEdit, room:RoomLight) {
			this.catalog = catalog;
			this.room = room;
			
			graphics.beginFill(EditorSettings.PALETTE_BACKCOLOR, 1);
			graphics.drawRect(0, 0, EditorSettings.PALETTE_XSIZE, EditorSettings.PALETTE_YSIZE);
			
			removeButton = new SimplerButton("Remove", removeSelectedItem, 0xff0000);
			removeButton.x = EditorSettings.PALETTE_XSIZE - 10 - removeButton.width;
			removeButton.y = 5;
			addChild(removeButton);
			
			walkerFacingFront = new Bitmap(new BitmapData(Prop.WIDTH, Prop.HEIGHT));
			Util.addBelow(walkerFacingFront, removeButton);
			walkerFacingFront.x = (EditorSettings.PALETTE_XSIZE - walkerFacingFront.width) / 2;
			
			var walkerChooser:ComboHolder = catalog.createChooser(CatalogEntry.WALKER, EditorSettings.PALETTE_XSIZE - 10);
			Util.addBelow(walkerChooser, walkerFacingFront, 10);
			walkerChooser.x = (EditorSettings.PALETTE_XSIZE - walkerChooser.width) / 2;
			walkerCombo = walkerChooser.comboBox;
			walkerCombo.addEventListener(Event.CHANGE, walkerComboBoxChanged);
			
			locationText = Util.textBox("", EditorSettings.PALETTE_XSIZE, Util.DEFAULT_TEXT_HEIGHT, TextFormatAlign.CENTER);
			Util.addBelow(locationText, walkerChooser, 10);
			
			attributeDisplay = createAttributeDisplay();
			Util.addBelow(attributeDisplay, locationText, 10);
			addChild(attributeDisplay);
			
			walkerCombo.selectedIndex = 0;
			walkerComboBoxChanged(null);
			
			room.addEventListener(Event.INIT, roomLoaded);
		}
		
		public function asSprite():Sprite {
			return this;
		}
		
		public function get tabLabel():String {
			return "NPCs";
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
			
			var talkLabel:TextField = Util.textBox("Conversation file:", EditorSettings.PALETTE_XSIZE-20);
			talkLabel.y = combatCombo.y + combatCombo.height + 10;
			holder.addChild(talkLabel);
			talkFile = FilenameControl.createBelow(talkLabel, true, null, 0, EditorSettings.PALETTE_XSIZE-10, changeTalk );
			
			return holder;
		}
		
		
		private function walkerComboBoxChanged(event:Event = null):void {
			var walkerId:String = walkerCombo.selectedLabel;
			
			var walkerImage:WalkerImage = catalog.retrieveWalkerImage(walkerId);
			walkerFacingFront.bitmapData = walkerImage.bitsFacing(1);
			
			updateAvailabilityAndAttributes();
			if ((event != null) && (locationOfCurrentSelection != null)) {
				room.snapToCenter(locationOfCurrentSelection);
			}
		}
		
		private function changeSelectionOnMapTo(location:Point):void {
			if (currentSelection != null) {
				currentSelection.filters = [];
			}
			currentSelection = room.propAt(location);
			if (currentSelection != null) {
				currentSelection.filters = [ RoomEditUI.SELECTION_GLOW_FILTER ];
			}
		}
		
		private function changeSelectionToContentsOf(location:Point):void {
			var id:String = room.idOfItemAt(location);
			if (id != null) {
				var comboEntry:Object = Util.itemWithLabelInComboBox(walkerCombo, id);
				walkerCombo.selectedItem = comboEntry;
				walkerComboBoxChanged();
			}
		}
		
		private function removeSelectedItem(event:Event):void {
			if (locationOfCurrentSelection != null) {
				room.removeItemAt(locationOfCurrentSelection);
				updateAvailabilityAndAttributes();
			}
		}
		
		private function updateAvailabilityAndAttributes():void {
			locationOfCurrentSelection = room.find(walkerCombo.selectedLabel);
			changeSelectionOnMapTo(locationOfCurrentSelection);
			var onMap:Boolean = (locationOfCurrentSelection != null);
			locationText.text = (onMap ? "Location: " + locationOfCurrentSelection : "Available");
			attributeDisplay.visible = onMap;
			
			if (onMap) {
				var attributes:Object = room.attributesOfItemAt(locationOfCurrentSelection);
				if (attributes == null) {
					exploreCombo.selectedIndex = 0;
					combatCombo.selectedIndex = 0;
					talkFile.text = "";
				} else {
					exploreCombo.selectedIndex = indexInChoices(exploreChoices, attributes["explore"]);
					combatCombo.selectedIndex = indexInChoices(combatChoices, attributes["combat"]);
					talkFile.text = attributes["talk"];
				}
			}
		}
		
		// UNDONE: Refactor and merge these!
		
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
		
		private function changeTalk(event:Event):void {
			var attributes:Object = room.attributesOfItemAt(locationOfCurrentSelection);
			if (attributes == null) {
				attributes = new Object();
			}
			attributes["talk"] = talkFile.text;
			room.setAttributesOfItemAt(locationOfCurrentSelection, attributes);
		}

		public function applyToTile(tile:FloorTileEdit, remove:Boolean = false):void {
			var occupied:Boolean = room.occupied(tile.location);
			if (remove && !occupied) {
				return;
			}
			if (occupied) {
				if (remove) {
					room.removeItemAt(tile.location);
				} else {
					changeSelectionToContentsOf(tile.location);
				}
			} else { // !occupied && !remove
				if (locationOfCurrentSelection == null) {
					//CONSIDER: this will need revision if we add resource management
					var prop:Prop = Prop.createFromBitmapData(walkerFacingFront.bitmapData);
					room.addContentItem(prop, CatalogEntry.WALKER, walkerCombo.selectedLabel, tile.location);
				} else {
					room.snapToCenter(locationOfCurrentSelection);
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