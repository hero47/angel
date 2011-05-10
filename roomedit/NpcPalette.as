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
	public class NpcPalette extends ContentPaletteCommonCode {
		private var locationText:TextField;
		private var attributeDisplay:Sprite;
		private var exploreCombo:ComboBox;
		private var combatCombo:ComboBox;
		private var exploreParameters:TextField;
		private var combatParameters:TextField;
		private var talkFile:FilenameControl;
		
		private static const exploreChoices:Vector.<String> = Vector.<String>(["", "fidget", "follow", "patrol", "wander"]);
		private static const combatChoices:Vector.<String> = Vector.<String>(["", "wander"]);
		
		public function NpcPalette(catalog:CatalogEdit, room:RoomLight) {
			super(catalog, room);
			
			locationText = Util.textBox("", EditorSettings.PALETTE_XSIZE, Util.DEFAULT_TEXT_HEIGHT, TextFormatAlign.CENTER);
			Util.addBelow(locationText, itemCombo, 5);
			
			attributeDisplay = createAttributeDisplay();
			Util.addBelow(attributeDisplay, locationText, 5);
			
			itemCombo.selectedIndex = 0;
			itemComboBoxChanged(null);
		}
		
		override public function get tabLabel():String {
			return "NPCs";
		}

		override public function applyToTile(tile:FloorTileEdit, remove:Boolean = false):void {
			super.applyToTile(tile, remove);
			updateAvailabilityAndAttributes();
		}
		
		// Whenever we become visible, update the walker location text
		override public function set visible(value:Boolean):void {
			super.visible = value;
			if (this.visible) {
				updateAvailabilityAndAttributes();
			}
		}
		
		override protected function get catalogEntryType():int {
			return CatalogEntry.WALKER;
		}
		
		override protected function roomLoaded(event:Event):void {
			if (this.visible) {
				updateAvailabilityAndAttributes();
			}
		}
		
		override protected function userClickedOccupiedTile(location:Point):void {
			var id:String = room.idOfItemAt(location);
			if (id != null) {
				var comboEntry:Object = Util.itemWithLabelInComboBox(itemCombo, id);
				if (comboEntry != null) {
					itemCombo.selectedItem = comboEntry;
					itemComboBoxChanged();
				}
			}
		}
		
		override protected function itemComboBoxChanged(event:Event = null):void {
			var walkerId:String = itemCombo.selectedLabel;
			
			var walkerImage:WalkerImage = catalog.retrieveWalkerImage(walkerId);
			itemImage.bitmapData = walkerImage.bitsFacing(1);
			
			updateAvailabilityAndAttributes();
			if ((event != null) && (locationOfCurrentSelection != null)) {
				room.snapToCenter(locationOfCurrentSelection);
			}
		}
		
		override protected function removeSelectedItem(event:Event):void {
			super.removeSelectedItem(event);
			updateAvailabilityAndAttributes();
		}
		
		override protected function attemptToCreateOneAt(location:Point):void {
			if (locationOfCurrentSelection == null) {
				//CONSIDER: this will need revision if we add resource management
				var prop:Prop = Prop.createFromBitmapData(itemImage.bitmapData);
				room.addContentItem(prop, CatalogEntry.WALKER, itemCombo.selectedLabel, location);
			} else {
				room.snapToCenter(locationOfCurrentSelection);
				Alert.show("Cannot place " + itemCombo.selectedLabel + " -- already in room.");
			}
		}
		
		private function createAttributeDisplay():Sprite {
			var holder:Sprite = new Sprite();
			
			var exploreLabel:TextField = Util.textBox("Explore mode behavior:", EditorSettings.PALETTE_XSIZE-20);
			holder.addChild(exploreLabel);
			exploreCombo = createBrainChooser(exploreChoices);
			Util.addBelow(exploreCombo, exploreLabel);
			exploreCombo.addEventListener(Event.CHANGE, function(event:Event):void {
				changeAttribute("explore", exploreCombo.selectedLabel);
			});
			exploreParameters = Util.createTextEditControlBelow(exploreCombo, null, 0, EditorSettings.PALETTE_XSIZE-10, function(event:Event):void {
				changeAttribute("exploreParam", exploreParameters.text);
			});
			
			var combatLabel:TextField = Util.textBox("Combat mode behavior:", EditorSettings.PALETTE_XSIZE-20);
			Util.addBelow(combatLabel, exploreParameters, 5);
			combatCombo = createBrainChooser(combatChoices);
			Util.addBelow(combatCombo, combatLabel);
			combatCombo.addEventListener(Event.CHANGE, function(event:Event):void {
				changeAttribute("combat", combatCombo.selectedLabel);
			});
			combatParameters = Util.createTextEditControlBelow(combatCombo, null, 0, EditorSettings.PALETTE_XSIZE-10, function(event:Event):void {
				changeAttribute("combatParam", combatParameters.text);
			});
			
			var talkLabel:TextField = Util.textBox("Conversation file:", EditorSettings.PALETTE_XSIZE-20);
			Util.addBelow(talkLabel, combatParameters, 10);
			talkFile = FilenameControl.createBelow(talkLabel, true, null, 0, EditorSettings.PALETTE_XSIZE-10, function(event:Event):void {
				changeAttribute("talk", talkFile.text);
			});
			
			return holder;
		}
		
		private function updateAvailabilityAndAttributes():void {
			locationOfCurrentSelection = room.find(itemCombo.selectedLabel);
			changeSelectionOnMapTo(locationOfCurrentSelection);
			var onMap:Boolean = (locationOfCurrentSelection != null);
			locationText.text = (onMap ? "Location: " + locationOfCurrentSelection : "Available");
			attributeDisplay.visible = onMap;
			
			if (onMap) {
				var attributes:Object = room.attributesOfItemAt(locationOfCurrentSelection);
				if (attributes == null) {
					exploreCombo.selectedIndex = 0;
					combatCombo.selectedIndex = 0;
					talkFile.text = exploreParameters.text = combatParameters.text = "";
				} else {
					exploreCombo.selectedItem = Util.itemWithLabelInComboBox(exploreCombo, attributes["explore"]);
					combatCombo.selectedItem = Util.itemWithLabelInComboBox(combatCombo, attributes["combat"]);
					talkFile.text = attributes["talk"];
					Util.nullSafeSetText(exploreParameters, attributes["exploreParam"]);
					Util.nullSafeSetText(combatParameters, attributes["combatParam"]);
				}
				adjustParamVisibilities();
			}
		}
		
		private function changeAttribute(attributeName:String, newValue:String):void {
			var attributes:Object = room.attributesOfItemAt(locationOfCurrentSelection);
			if (attributes == null) {
				attributes = new Object();
			}
			attributes[attributeName] = newValue;
			if (newValue == "") {
				if (attributeName == "explore") {
					attributes["exploreParam"] = "";
				} else if (attributeName == "combat") {
					attributes["combatParam"] = "";
				}
			}
			
			room.setAttributesOfItemAt(locationOfCurrentSelection, attributes);
			adjustParamVisibilities();
		}
		
		private function adjustParamVisibilities():void {
			exploreParameters.visible = (exploreCombo.selectedIndex != 0);
			combatParameters.visible = (combatCombo.selectedIndex != 0);
		}
		
		private function createBrainChooser(choices:Vector.<String>):ComboBox {
			var combo:ComboBox = new ComboBox();
			combo.width = EditorSettings.PALETTE_XSIZE - 10;
			for (var i:int = 0; i < choices.length; i++) {
				combo.addItem( { label:choices[i] } );
			}
			return combo;
		}
		
	} // end class NpcPalette

}