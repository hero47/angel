package angel.common {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	// The simple, most lightweight thing that can inhabit a room.  Room editor uses these directly; game extends
	// them.
	// CONSIDER: Room editor creates these either from a cataloged PropImage (when loading) or directly from
	// a bitmap (when adding to the map by clicking a tile).  That may need to change when we get resource management.
	public class Prop extends Sprite {

		// ORing together the solidity for everything on a tile must give solidity for the tile as a whole.
		public static const SOLID:uint = 0x1;	// normal solid object, prevents movement (default)
		public static const HARD_CORNER:uint = 0x2; // prevent movement between two adjacent diagonals if both hard
		public static const TALL:uint = 0x4; // block line of sight (default) (optional "short" setting doesn't)
		
		public static const DEFAULT_SOLIDITY:uint = (SOLID | TALL);
		public static const OFF_MAP:uint = (SOLID | HARD_CORNER | TALL);
		
		protected var imageBitmap:Bitmap;
		protected var myLocation:Point = null;
		public var solidness:uint = Prop.DEFAULT_SOLIDITY;
		
		// Depth represents distance to the "camera" plane, in our orthogonal view
		// The fractional part of depth indicates distance away from that line of cell-centers
		protected var myDepth:Number = -Infinity;
		
		// Size of art assets for prop
		// NOTE: the prop itself may be shorter than this!
		public static const WIDTH:int = 64;
		public static const HEIGHT:int = 128;
		
		public function Prop(bitmap:Bitmap = null) {
			imageBitmap = bitmap;
			if (imageBitmap != null) {
				 // for convenience, make 0,0 of prop be the same location as 0,0 of the tile it's standing on
				imageBitmap.y = -imageBitmap.height + Tileset.TILE_HEIGHT;
				addChild(imageBitmap);
			}
		}
		
		public function cleanup():void {
			// Currently does nothing, but eventually we'll be doing resource tracking and need to
			// decrement a count in the catalog.
		}
		
		public static function createFromBitmapData(bitmapData:BitmapData):Prop {
			return new Prop(new Bitmap(bitmapData));
		}
		
		public static function createFromPropImage(propImage:PropImage):Prop {
			return new Prop(new Bitmap(propImage.imageData));
		}
		

		public function get location():Point {
			//Assert.assertTrue(parent != null, "Getting location of an entity not on stage");
			return myLocation;
		}
		
		public function set location(newLocation:Point):void {
			myLocation = newLocation;
			myDepth = newLocation.x + newLocation.y;
			var pixels:Point = pixelLocStandingOnTile(newLocation);
			this.x = pixels.x;
			this.y = pixels.y;
			//Assert.assertTrue(parent != null, "Setting location of an entity not on stage");
			if (parent != null) {
				adjustDrawOrder();
			}
		}
		
		protected function pixelLocStandingOnTile(tileLoc:Point):Point {
			var tilePixelLoc:Point = Floor.tileBoxCornerOf(tileLoc);
			return new Point(tilePixelLoc.x, tilePixelLoc.y);
		}
		
		protected function get depth():Number {
			return myDepth;
		}

		// CAUTION: Depends on all children in content layer being Prop
		protected function adjustDrawOrder():void {
			var index:int = parent.getChildIndex(this);
			var correctIndex:int;
			var other:Prop = null;
			// Assuming depth is currently correct or too low, find index I should move to
			for (correctIndex = index; correctIndex > 0; correctIndex--) {
				other = Prop(parent.getChildAt(correctIndex - 1));
				if (other.depth < myDepth) {
					break;
				}
			}
			if (correctIndex == index) {
				//That didn't find a move, so depth must be correct or too high.
				for (correctIndex = index; correctIndex < parent.numChildren-1; correctIndex++) {
					other = Prop(parent.getChildAt(correctIndex + 1));
					if (other.depth > myDepth) {
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