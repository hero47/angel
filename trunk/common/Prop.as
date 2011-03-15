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

		protected var imageBitmap:Bitmap;
		protected var myLocation:Point = null;
		public var solid:Boolean = false;
		
		// Depth represents distance to the "camera" plane, in our orthogonal view
		// The fractional part of depth indicates distance away from that line of cell-centers
		protected var myDepth:Number = -Infinity;
		
		// Size of art assets for prop
		public static const WIDTH:int = 64;
		public static const HEIGHT:int = 128;
		
		// offsets from top corner of a tile's bounding box, to top corner of prop's bounding box when standing on it
		private static const OFFSET_X:int = 0;
		private static const OFFSET_Y:int = -96;
		
		
		public function Prop(bitmap:Bitmap = null) {
			imageBitmap = bitmap;
			if (bitmap != null) {
				addChild(imageBitmap);
			}
		}
		
		public static function createFromBitmapData(bitmapData:BitmapData):Prop {
			return new Prop(new Bitmap(bitmapData));
		}
		
		public static function createFromPropImage(propImage:PropImage):Prop {
			return new Prop(new Bitmap(propImage.imageData));
		}
		

		public function get location():Point {
			Assert.assertTrue(parent != null, "Getting location of an entity not on stage");
			return myLocation;
		}
		
		public function set location(newLocation:Point):void {
			myLocation = newLocation;
			myDepth = newLocation.x + newLocation.y;
			var pixels:Point = pixelLocStandingOnTile(newLocation);
			this.x = pixels.x;
			this.y = pixels.y;
			Assert.assertTrue(parent != null, "Setting location of an entity not on stage");
			if (parent != null) {
				adjustDrawOrder();
			}
		}
		
		protected function pixelLocStandingOnTile(tileLoc:Point):Point {
			var tilePixelLoc:Point = Floor.tileBoxCornerOf(tileLoc);
			return new Point(tilePixelLoc.x + OFFSET_X, tilePixelLoc.y + OFFSET_Y);
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