package angel.roomedit {
	import angel.common.Alert;
	import angel.common.Floor;
	import angel.common.KludgeDialogBox;
	import angel.common.SimplerButton;
	import angel.common.Tileset;
	import angel.common.Util;
	import angel.roomedit.FloorTileEdit;
	import fl.controls.CheckBox;
	import fl.controls.ComboBox;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class SpotPalette extends Sprite implements IRoomEditorPalette {
		
		private var room:RoomLight;
		private var spotCombo:ComboBox; // The list in box doubles as a place to look up spot markers by id or location
		private var locationText:TextField;
		private var lockCheck:CheckBox;
		private var deleteButton:SimplerButton;
		
		private var selectedComboEntry:SpotComboEntry;
		
		public function SpotPalette(catalog:CatalogEdit, room:RoomLight) {
			this.room = room;
			room.addEventListener(Event.INIT, roomInitListener);
			
			graphics.beginFill(EditorSettings.PALETTE_BACKCOLOR, 1);
			graphics.drawRect(0, 0, EditorSettings.PALETTE_XSIZE, EditorSettings.PALETTE_YSIZE);
			
			deleteButton = new SimplerButton("Delete", deleteSelectedSpot, 0xff0000);
			deleteButton.x = EditorSettings.PALETTE_XSIZE - 10 - deleteButton.width;
			deleteButton.y = 5;
			addChild(deleteButton);
			
			var label:TextField = Util.textBox("Spot id:", EditorSettings.PALETTE_XSIZE-20);
			Util.addBelow(label, deleteButton, 15);
			label.x = 0;
			
			spotCombo = new ComboBox();
			spotCombo.width = EditorSettings.PALETTE_XSIZE - 10;
			Util.addBelow(spotCombo, label);
			spotCombo.addEventListener(Event.CHANGE, comboBoxChanged);
			
			lockCheck = Util.createCheckboxEditControlBelow(spotCombo, "Lock selection to palette", 150, null);
			//lockCheck.y = spotIdCombo.y + spotIdCombo.height;
			addChild(lockCheck);
			
			locationText = Util.textBox("", EditorSettings.PALETTE_XSIZE, Util.DEFAULT_TEXT_HEIGHT, TextFormatAlign.CENTER);
			Util.addBelow(locationText, lockCheck, 10);
			
			var newSpotButton:SimplerButton = new SimplerButton("Add New", launchCreateSpotDialog);
			Util.addBelow(newSpotButton, locationText, 20);
			newSpotButton.x = (EditorSettings.PALETTE_XSIZE - newSpotButton.width) / 2;
			
			initSpotsFromRoom();
		}
		
		/* INTERFACE angel.roomedit.IRoomEditorPalette */
		
		public function asSprite():Sprite {
			return this;
		}
		
		public function get tabLabel():String {
			return "Spots";
		}
		
		public function applyToTile(floorTile:FloorTileEdit, remove:Boolean = false):void {
			if (spotCombo.length == 0) {
				Alert.show("Create a spot marker with the 'Add New' button,\nthen click the map to move it.");
				return;
			}
			if (remove) {
				deleteSpotAtLocation(floorTile.location);
			} else {
				selectOrMoveSelectionTo(floorTile.location);
			}
		}
		
		public function paintWhileDragging():Boolean {
			return false;
		}
		
		/******** internal ********/
		
		private function initSpotsFromRoom():void {
			for (var id:String in room.spots) {
				addSpotMarker(id);
			}
			if (spotCombo.length > 0) {
				spotCombo.sortItems();
				spotCombo.selectedIndex = 0;
				comboBoxChanged();
			}
		}
		
		private function roomInitListener(event:Event):void {
			for (var i:int = 0; i < spotCombo.length; ++i) {
				room.spotLayer.removeChild(SpotComboEntry(spotCombo.getItemAt(i)).marker);
			}
			spotCombo.removeAll();
			selectedComboEntry = null;
			initSpotsFromRoom();
		}
		
		private function changeSelection(newSelection:SpotComboEntry):void {
			spotCombo.selectedItem = newSelection;
			comboBoxChanged();
		}
		
		private function comboBoxChanged(event:Event = null):void {
			var comboEntry:SpotComboEntry = SpotComboEntry(spotCombo.selectedItem);
			changeSelectedSpotToMatch(comboEntry);
			setLocationText();
			if ((event != null) && (comboEntry!= null)) {
				room.snapToCenter(comboEntry.location);
			}
		}
		
		private function selectOrMoveSelectionTo(location:Point):void {
			var entryToSelect:SpotComboEntry;
			if (!lockCheck.selected) {
				entryToSelect = nextEntryAtLocation(location, spotCombo.selectedIndex);
			}

			if (entryToSelect == null) {
				moveSelectedSpotTo(location);
			} else {
				changeSelection(entryToSelect);
			}
		}
		
		// Selected spot appears "on top" to human intuition, so if it's at that location delete it. Otherwise delete first one.
		private function deleteSpotAtLocation(location:Point):void {
			if (selectedComboEntry.location.equals(location)) {
				deleteSpotAndAdjustCombo(selectedComboEntry);
			} else {
				var entry:SpotComboEntry = nextEntryAtLocation(location, -1);
				if (entry != null) {
					deleteSpotAndAdjustCombo(entry);
				}
			}
		}
		
		private function launchCreateSpotDialog(event:Event):void {
			var options:Object = { buttons:["OK", "Cancel"], inputs:["id:"], restricts:["A-Za-z0-9_"], callback:userEnteredNewSpotId };
			KludgeDialogBox.show("Create new spot", options);
		}
		
		private function userEnteredNewSpotId(buttonClicked:String, values:Array):void {
			if (buttonClicked != "OK") {
				return;
			}
			var id:String = values[0];
			if (room.spots[id] != null) {
				Alert.show("This room already has a spot with id " + id + ".");
				return;
			}
			room.spots[id] = new Point(0, 0);
			var newComboEntry:SpotComboEntry = addSpotMarker(id);
			spotCombo.sortItems();
			spotCombo.selectedItem = newComboEntry;
			comboBoxChanged();
		}
		
		private function changeSelectedSpotToMatch(comboEntry:SpotComboEntry):void {
			if (selectedComboEntry != null) {
				selectedComboEntry.marker.filters = [];
			}
			selectedComboEntry = comboEntry;
			if (selectedComboEntry != null) {
				selectedComboEntry.marker.filters = RoomEditUI.FILTERS_FOR_SELECTED_ITEM;
			}
		}
		
		// If there are multiple marks on the same tile, we want clicking repeatedly on that tile to cycle through them
		// in the order they are listed in the combobox.
		private function nextEntryAtLocation(location:Point, startAfterIndex:int):SpotComboEntry {
			var numberOfSpots:int = spotCombo.length;
			for (var i:int = startAfterIndex + 1; i < startAfterIndex + 1 + numberOfSpots; ++i) {
				var comboEntry:SpotComboEntry = SpotComboEntry(spotCombo.getItemAt(i % numberOfSpots));
				if (comboEntry.location.equals(location)) {
					return comboEntry;
				}
			}
			return null;
		}
		
		private function firstEntryAtLocation(location:Point):SpotComboEntry {
			return nextEntryAtLocation(location, -1);
		}
		
		private function moveSelectedSpotTo(location:Point):void {
			room.spots[selectedComboEntry.label] = location;
			selectedComboEntry.location = location;
			var coords:Point = Floor.tileBoxCornerOf(location);
			selectedComboEntry.marker.x = coords.x;
			selectedComboEntry.marker.y = coords.y;
			setLocationText();
		}
		
		private function deleteSelectedSpot(event:Event):void {
			if (selectedComboEntry != null) {
				deleteSpotAndAdjustCombo(selectedComboEntry);
			}
		}
		
		private function deleteSpotAndAdjustCombo(comboEntryToDelete:SpotComboEntry):void {
			delete room.spots[comboEntryToDelete.label];
			room.spotLayer.removeChild(comboEntryToDelete.marker);
			spotCombo.removeItem(comboEntryToDelete);
			if (comboEntryToDelete == selectedComboEntry) {
				var currentIndex:int = spotCombo.selectedIndex;
				if (currentIndex >= spotCombo.length) {
					--currentIndex; // index -1 will clear selection
				}
				spotCombo.selectedIndex = currentIndex;
				comboBoxChanged();
			}
		}
		
		private function setLocationText():void {
			locationText.text = (selectedComboEntry == null ? "" : "Location: " + selectedComboEntry.location);
		}
		
		private function addSpotMarker(id:String):SpotComboEntry {
			var location:Point = room.spots[id];
			var mark:Shape = new Shape();
			var w:int = Tileset.TILE_WIDTH / 3;
			var h:int = Tileset.TILE_HEIGHT / 3;
			mark.graphics.lineStyle(6, 0x0, 1);
			drawX(mark.graphics, w, h);
			mark.graphics.lineStyle(3, 0xffffff, 1);
			drawX(mark.graphics, w, h);
			var coords:Point = Floor.tileBoxCornerOf(location);
			mark.x = coords.x;
			mark.y = coords.y;
			room.spotLayer.addChild(mark);
			
			var comboEntry:SpotComboEntry = new SpotComboEntry(id, mark, location);
			spotCombo.addItem(comboEntry);
			return comboEntry;
		}
		
		private function drawX(graphics:Graphics, w:int, h:int):void {
			graphics.moveTo(w, h);
			graphics.lineTo(Tileset.TILE_WIDTH - w, Tileset.TILE_HEIGHT - h);
			graphics.moveTo(w, Tileset.TILE_HEIGHT - h);
			graphics.lineTo(Tileset.TILE_WIDTH - w, h);
		}
		
	}

}
import flash.display.DisplayObject;
import flash.geom.Point;

class SpotComboEntry {
	public var label:String
	public var marker:DisplayObject;
	public var location:Point;
	public var icon:Object = null; // Clicking dropdown crashes with Error #1069: Property icon not found if don't have this????
	public function SpotComboEntry(label:String, marker:DisplayObject, location:Point) {
		this.label = label;
		this.marker = marker;
		this.location = location;
	}
}