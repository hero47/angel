package angel.common {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	// The simple, most lightweight thing that can inhabit a room.  Room editor uses these directly; game extends
	// them.
	// CONSIDER: Room editor creates these either from a cataloged PropImage (when loading) or directly from
	// a bitmap (when adding to the map by clicking a tile).  That may need to change when we get resource management.
	public class Prop extends Sprite implements ICleanup {

		// ORing together the solidity for everything on a tile must give solidity for the tile as a whole.
		public static const SOLID:uint = 0x1;	// normal solid object, prevents movement (default)
		public static const HARD_CORNER:uint = 0x2; // prevent movement between two adjacent diagonals if both hard
		public static const TALL:uint = 0x4; // block line of sight (default) (optional "short" setting doesn't)
		public static const FILLS_TILE:uint = 0x8; // takes up so much space that you can't throw things at this square
												//NOTE: currently (5/7/11) also controls whether it gives blast shadow!
		
		public static const DEFAULT_SOLIDITY:uint = (SOLID | TALL | FILLS_TILE);
		public static const OFF_MAP:uint = (SOLID | HARD_CORNER | TALL | FILLS_TILE);
		public static const DEFAULT_CHARACTER_SOLIDITY:uint = (SOLID | TALL); // these can't currently be changed
		
		protected var imageBitmap:Bitmap;
		protected var myLocation:Point = null;
		public var solidness:uint = Prop.DEFAULT_SOLIDITY;
		
		// Depth represents distance to the "camera" plane, in our orthogonal view
		// The fractional part of depth indicates distance away from that line of cell-centers
		public var depth:Number = -Infinity;
		
		// Size of art assets for prop
		// NOTE: the prop itself may be shorter than this!
		public static const WIDTH:int = 64;
		public static const HEIGHT:int = 128;
		
		public function Prop(bitmap:Bitmap = null) {
			imageBitmap = bitmap;
			if (imageBitmap != null) {
				fixHeightOffset(imageBitmap.height);
				addChild(imageBitmap);
			}
			location = new Point(0, 0);
		}
		
		public function cleanup():void {
			if (parent != null) {
				parent.removeChild(this);
			}
		}
		
		public static function createFromBitmapData(bitmapData:BitmapData):Prop {
			return new Prop(new Bitmap(bitmapData));
		}
		
		public function changeImage(bitmapData:BitmapData):void {
			imageBitmap.bitmapData = bitmapData;
			fixHeightOffset(imageBitmap.height);
		}
		
		// We keep 0,0 of prop the same location as 0,0 of the tile it's standing on, regardless of image height
		private function fixHeightOffset(imageHeight:int):void {
			imageBitmap.y = -imageHeight + Tileset.TILE_HEIGHT;			
		}
		

		public function get location():Point {
			//Assert.assertTrue(parent != null, "Getting location of an entity not on stage");
			return myLocation;
		}

		//WARNING! If this prop is in a Room, use room.changeEntityLocation or the cell contents won't match location!
		public function set location(newLocation:Point):void {
			myLocation = newLocation;
			moveToCenterOfTile();
		}
		
		//This should only be called by routines that are manipulating partial depth (for positions "between" tiles)
		public function setLocationWithoutChangingDepth(newLocation:Point):void {
			myLocation = newLocation;
		}
		
		public function moveToCenterOfTile():void {
			depth = myLocation.x + myLocation.y;
			var pixels:Point = pixelLocStandingOnTile(myLocation);
			this.x = pixels.x;
			this.y = pixels.y;
			//Assert.assertTrue(parent != null, "Setting location of an entity not on stage");
			if (parent != null) {
				adjustDrawOrder();
			}
		}
		
		public function pixelLocStandingOnTile(tileLoc:Point):Point {
			var tilePixelLoc:Point = Floor.tileBoxCornerOf(tileLoc);
			return new Point(tilePixelLoc.x, tilePixelLoc.y);
		}

		// CAUTION: Depends on all children in content layer being Prop
		public function adjustDrawOrder():void {
			var index:int = parent.getChildIndex(this);
			var correctIndex:int;
			var other:Prop = null;
			// Assuming depth is currently correct or too low, find index I should move to
			for (correctIndex = index; correctIndex > 0; correctIndex--) {
				other = Prop(parent.getChildAt(correctIndex - 1));
				if (other.depth < depth) {
					break;
				}
			}
			if (correctIndex == index) {
				//That didn't find a move, so depth must be correct or too high.
				for (correctIndex = index; correctIndex < parent.numChildren-1; correctIndex++) {
					other = Prop(parent.getChildAt(correctIndex + 1));
					if (other.depth > depth) {
						break;
					}
				}
			}
			
			if (correctIndex != index) {
				parent.setChildIndex(this, correctIndex);
			}

		}
		
	}

}