package angel.game.combat {
	import angel.common.Floor;
	import angel.common.Prop;
	import angel.common.Tileset;
	import angel.game.Room;
	import angel.game.Settings;
	import flash.events.Event;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ThrowAnimation {
		
		[Embed(source = '../../EmbeddedAssets/prp_grenade_tile.png')]
		public static const FlyingGrenade:Class;
		
		private var room:Room;
		private var payloadFunction:Function;
		private var flying:Prop;
		private var dx:Number;
		private var dy:Number;
		private var dDepth:Number;
		private var flyingTargetLocation:Point;
		private var movesLeft:int;
		private var paused:Boolean;

		private var vertPosition:int;
		private var vertVelocity:int;
		
		public function ThrowAnimation(room:Room, start:Point, end:Point, payloadFunction:Function) {
			this.room = room;
			this.payloadFunction = payloadFunction;
			flyingTargetLocation = end;
			flying = new Prop(new FlyingGrenade());
			room.contentsLayer.addChild(flying);
			flying.location = start;
			var startCoord:Point = Floor.tileBoxCornerOf(start);
			var endCoord:Point = Floor.tileBoxCornerOf(end);
			
			movesLeft = Settings.FRAMES_PER_SECOND;
			dx = (endCoord.x - startCoord.x) / movesLeft;
			dy = (endCoord.y - startCoord.y) / movesLeft;
			dDepth = ((end.x + end.y) - flying.depth) / movesLeft;
			flying.addEventListener(Event.ENTER_FRAME, enterFrameListener);
			
			vertVelocity = movesLeft/2;
			vertPosition = Tileset.TILE_HEIGHT / 2;
			flying.y -= vertPosition;
		}
		
		private function enterFrameListener(event:Event):void {
			if (!paused) {
				room.pauseGameTimeIndefinitely(this);
				paused = true;
			}
			if (--movesLeft > 0) {
				flying.y += vertPosition;
				flying.x += dx;
				flying.y += dy;
				flying.depth += dDepth;
				trace(flying.depth);
				flying.adjustDrawOrder();
				
				vertVelocity--;
				vertPosition = Math.max(vertPosition + vertVelocity, 0);
				flying.y -= vertPosition;
			} else {
				flying.removeEventListener(Event.ENTER_FRAME, enterFrameListener);
				room.unpauseFromLastIndefinitePause(this);
				flying.parent.removeChild(flying);
				flying = null;
				payloadFunction(room, flyingTargetLocation);
			}
		}
		
	}

}