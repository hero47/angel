package angel.roomedit {
	import angel.common.CatalogEntry;
	import angel.common.Prop;
	import angel.common.SimplerButton;
	import angel.common.Tileset;
	import angel.common.Util;
	import angel.roomedit.FloorTileEdit;
	import fl.controls.ComboBox;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ContentPaletteCommonCode extends Sprite implements IRoomEditorPalette {
		protected var catalog:CatalogEdit;
		protected var room:RoomLight;
		protected var removeButton:SimplerButton;
		protected var itemImage:Bitmap;
		protected var itemChooser:ComboHolder;
		protected var itemCombo:ComboBox;
		protected var attributeDisplay:Sprite;
		
		protected var currentSelection:Prop;
		protected var locationOfCurrentSelection:Point;
		
		public function ContentPaletteCommonCode(catalog:CatalogEdit, room:RoomLight) {
			this.catalog = catalog;
			this.room = room;
			
			graphics.beginFill(EditorSettings.PALETTE_BACKCOLOR, 1);
			graphics.drawRect(0, 0, EditorSettings.PALETTE_XSIZE, EditorSettings.PALETTE_YSIZE);
			
			removeButton = new SimplerButton("Remove", removeSelectedItem, 0xff0000);
			removeButton.x = EditorSettings.PALETTE_XSIZE - 10 - removeButton.width;
			removeButton.y = 5;
			addChild(removeButton);
			
			itemImage = new Bitmap(new BitmapData(Prop.WIDTH, Prop.HEIGHT));
			Util.addBelow(itemImage, removeButton);
			itemImage.x = (EditorSettings.PALETTE_XSIZE - itemImage.width) / 2;
			
			itemChooser = catalog.createChooser(catalogEntryType, EditorSettings.PALETTE_XSIZE - 10);
			Util.addBelow(itemChooser, itemImage, -(Tileset.TILE_HEIGHT/2));
			itemChooser.x = (EditorSettings.PALETTE_XSIZE - itemChooser.width) / 2;
			itemCombo = itemChooser.comboBox;
			itemCombo.addEventListener(Event.CHANGE, itemComboBoxChanged);
			
			attributeDisplay = createAttributeDisplay();
			
			room.addEventListener(Event.INIT, roomLoaded);
		}
		
		/* INTERFACE angel.roomedit.IRoomEditorPalette */
		
		public function asSprite():Sprite {
			return this;
		}
		
		// override this
		public function get tabLabel():String {
			return "";
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
					userClickedOccupiedTile(tile.location);
				}
			} else { // !occupied && !remove
				attemptToCreateOneAt(tile.location);
			}
			updateAvailabilityAndAttributes();
		}
		
		public function paintWhileDragging():Boolean {
			return false;
		}
		
		/* not interface, but shared by both types of content item palettes (and presumably others we might invent later) */
		
		// Each palette has its own selection. Show/hide ours appropriately.
		override public function set visible(value:Boolean):void {
			super.visible = value;
			var filters:Array;
			if (this.visible) {
				// Our selection might have been deleted while another palette was active!
				if ((currentSelection != null) && (currentSelection.parent == null)) {
					clearSelection();
				} else {
					filters = RoomEditUI.FILTERS_FOR_SELECTED_ITEM;
				}
			} else {
				filters = [];
			}
			if (currentSelection != null) {
				currentSelection.filters = filters;
			}
			if (this.visible) {
				updateAvailabilityAndAttributes();
			}
		}
		
		protected function get catalogEntryType():int {
			return CatalogEntry.PROP;
		}
		
		protected function roomLoaded(event:Event):void {
			// override this
		}
		
		protected function changeSelectionOnMapTo(location:Point):void {
			if (currentSelection != null) {
				currentSelection.filters = [];
			}
			currentSelection = room.propAt(location);
			if (currentSelection != null) {
				currentSelection.filters = RoomEditUI.FILTERS_FOR_SELECTED_ITEM;
			}
			
		}
		
		protected function userClickedOccupiedTile(location:Point):void {
			// override this
		}
		
		protected function removeSelectedItem(event:Event):void {
			if (locationOfCurrentSelection != null) {
				room.removeItemAt(locationOfCurrentSelection);
			}
		}
		
		protected function itemComboBoxChanged(event:Event = null):void {
			// Override this
		}
		
		protected function attemptToCreateOneAt(location:Point):void {
			// Override this
		}
		
		protected function clearSelection():void {
			currentSelection = null;
			locationOfCurrentSelection = null;
		}
		
		protected function createAttributeDisplay():Sprite {
			// override this
			return null;
		}
		
		protected function changeAttribute(attributeName:String, newValue:String):void {
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
		}
		
		protected function updateAvailabilityAndAttributes():void {
			//override this
		}
		
	}

}