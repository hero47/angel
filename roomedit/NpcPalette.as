package angel.roomedit {
	import angel.common.Alert;
	import angel.common.CatalogEntry;
	import angel.common.Prop;
	import angel.common.RoomContentResource;
	import angel.common.Util;
	import fl.controls.CheckBox;
	import fl.controls.ComboBox;
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
			
		private static const COMBO_WIDTH:int = EditorSettings.PALETTE_XSIZE - 10;
			
		private var locationText:TextField;
		private var exploreCombo:ComboBox;
		private var combatCombo:ComboBox;
		private var exploreParameters:TextField;
		private var combatParameters:TextField;
		private var scriptFile:FilenameControl;
		private var factionCombo:ComboBox;
		private var downCheckbox:CheckBox;
		
		private static const exploreChoices:Vector.<String> = Vector.<String>(["", "fidget", "follow", "patrol", "wander"]);
		private static const combatChoices:Vector.<String> = Vector.<String>(["", "patrol", "patrolNoStops", "wander"]);
		//NOTE: faction is index in factionChoices, not the string itself
		private static const factionChoices:Vector.<String> = Vector.<String>(["enemy", "friend", "non-aligned", "enemy2"]);
		
		public function NpcPalette(catalog:CatalogEdit, room:RoomLight) {
			super(catalog, room);
			
			locationText = Util.textBox("", EditorSettings.PALETTE_XSIZE, Util.DEFAULT_TEXT_HEIGHT, TextFormatAlign.CENTER);
			Util.addBelow(locationText, itemCombo, 5);
			
			Util.addBelow(attributeDisplay, locationText, 5);
			
			itemCombo.selectedIndex = 0;
			itemComboBoxChanged(null);
		}
		
		override public function get tabLabel():String {
			return "NPCs";
		}
		
		override protected function get catalogEntryType():Class {
			return CatalogEntry.CHARACTER;
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
			
			var resource:RoomContentResource = catalog.retrieveCharacterResource(walkerId);
			itemImage.bitmapData = resource.standardImage();
			
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
				room.addContentItem(prop, CatalogEntry.CHARACTER, itemCombo.selectedLabel, location);
			} else {
				room.snapToCenter(locationOfCurrentSelection);
				Alert.show("Cannot place " + itemCombo.selectedLabel + " -- already in room.");
			}
		}
		
		override protected function changeAttribute(attributeName:String, newValue:String):void {
			super.changeAttribute(attributeName, newValue);
			adjustParamVisibilities();
		}
		
		override protected function createAttributeDisplay():Sprite {
			var holder:Sprite = new Sprite();
			
			var exploreLabel:TextField = Util.textBox("Explore mode behavior:", EditorSettings.PALETTE_XSIZE-20);
			holder.addChild(exploreLabel);
			exploreCombo = Util.createChooserFromStringList(exploreChoices, COMBO_WIDTH,
							function(event:Event):void { changeAttribute("explore", exploreCombo.selectedLabel); } );
			Util.addBelow(exploreCombo, exploreLabel);
			exploreParameters = Util.createTextEditControlBelow(exploreCombo, null, 0, EditorSettings.PALETTE_XSIZE-10, function(event:Event):void {
				changeAttribute("exploreParam", exploreParameters.text);
			});
			
			var combatLabel:TextField = Util.textBox("Combat mode behavior:", EditorSettings.PALETTE_XSIZE-20);
			Util.addBelow(combatLabel, exploreParameters, 5);
			combatCombo = Util.createChooserFromStringList(combatChoices, COMBO_WIDTH,
							function(event:Event):void { changeAttribute("combat", combatCombo.selectedLabel); } );
			Util.addBelow(combatCombo, combatLabel);
			combatParameters = Util.createTextEditControlBelow(combatCombo, null, 0, EditorSettings.PALETTE_XSIZE-10, function(event:Event):void {
				changeAttribute("combatParam", combatParameters.text);
			});
			
			var talkLabel:TextField = Util.textBox("Conversation/Script file:", EditorSettings.PALETTE_XSIZE-20);
			Util.addBelow(talkLabel, combatParameters, 10);
			scriptFile = FilenameControl.createBelow(talkLabel, true, null, 0, EditorSettings.PALETTE_XSIZE-10, function(event:Event):void {
				changeAttribute("script", scriptFile.text);
			});
			
			factionCombo = Util.createChooserFromStringList(factionChoices, COMBO_WIDTH,
							function(event:Event):void { changeAttribute("faction", String(factionCombo.selectedIndex)); } );
			Util.addBelow(factionCombo, scriptFile);
			
			downCheckbox = Util.createCheckboxEditControlBelow(factionCombo, "Down", EditorSettings.PALETTE_XSIZE, changeDown);
			
			return holder;
		}
		
		override protected function updateAvailabilityAndAttributes():void {
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
					scriptFile.text = exploreParameters.text = combatParameters.text = "";
				} else {
					exploreCombo.selectedItem = Util.itemWithLabelInComboBox(exploreCombo, attributes["explore"]);
					combatCombo.selectedItem = Util.itemWithLabelInComboBox(combatCombo, attributes["combat"]);
					scriptFile.text = attributes["script"];
					Util.nullSafeSetText(exploreParameters, attributes["exploreParam"]);
					Util.nullSafeSetText(combatParameters, attributes["combatParam"]);
					factionCombo.selectedIndex = int(attributes["faction"]);
					downCheckbox.selected = (attributes["down"] == "yes");
				}
				adjustParamVisibilities();
			}
		}
		
		private function adjustParamVisibilities():void {
			exploreParameters.visible = (exploreCombo.selectedIndex != 0);
			combatParameters.visible = (combatCombo.selectedIndex != 0);
		}
		
		private function changeDown(event:Event):void {
			var down:Boolean = downCheckbox.selected;
			changeAttribute("down", down ? "yes" : null);
			var resource:RoomContentResource = catalog.retrieveRoomContentResource(itemCombo.selectedLabel, CatalogEntry.CHARACTER);
			var bitmapData:BitmapData = resource.standardImage(down);
			room.propAt(locationOfCurrentSelection).changeImage(bitmapData);
		}
		
	} // end class NpcPalette

}