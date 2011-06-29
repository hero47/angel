package angel.common {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	public class FloorTile extends Sprite {
		private var image:Bitmap;
		private var roomLoc:Point = null;
		public var visibility:int; // one of the visibility constants from Floor
		
		// location is cached in the tile for the convenience of users; it's not actually used
		// by the tile itself.
		public function FloorTile(bitmapData:BitmapData, roomX:int = -1, roomY:int = -1):void {
			this.image = new Bitmap(bitmapData);
			addChild(image);
			var hitArea:Sprite = createHitArea();
			hitArea.visible = false;
			hitArea.mouseEnabled = false;
			addChild(hitArea);
			this.hitArea = hitArea;
			if (roomX > -1) {
				roomLoc = new Point(roomX, roomY);
			}
		}

		public function set bitmapData(newBitmapData:BitmapData):void {
			image.bitmapData = newBitmapData;
		}
		
		public function get location():Point {
			return roomLoc;
		}
		
		private function createHitArea():Sprite {
			var sprite:Sprite = new Sprite();
			sprite.graphics.beginFill(0);
			sprite.graphics.moveTo(this.width/2, 0);
			sprite.graphics.lineTo(this.width, this.height / 2);
			sprite.graphics.lineTo(this.width / 2, this.height);
			sprite.graphics.lineTo(0, this.height / 2);
			sprite.graphics.endFill();
			return sprite;
		}
		
	} // end class FloorTile
	
}