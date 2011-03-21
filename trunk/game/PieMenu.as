package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Util;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class PieMenu extends Sprite {
		
		private static const RADIUS:int = 80;
		private static const PIE_COLOR:uint = 0x888888;
		private static const PIE_BORDER_COLOR:uint = 0xcccccc;
		private static const PIE_ALPHA:Number = 0.5;
		private static const ICON_ALPHA:Number = 0.5;
		private static const CENTER_OF_FIRST_SLICE:int = 180;
		public static const ICON_SIZE:int = 28; // square
		
		private var slices:Vector.<PieSlice>;
		private var pie:Sprite;
		private var facingFirstSliceEdge:int;
		private var sliceDegrees:int;
		
		private var overIcon:Bitmap;
		
		public function PieMenu(centerX:int, centerY:int, slices:Vector.<PieSlice>) {
			this.slices = slices;
			Assert.assertTrue(slices != null && slices.length > 0, "Pie menu missing data");
			
			createPie();
			pie.x = centerX;
			pie.y = centerY;
			addChild(pie);
			pie.addEventListener(MouseEvent.CLICK, clickedPie);
			pie.addEventListener(MouseEvent.MOUSE_MOVE, mouseOverPie);
			
			addEventListener(MouseEvent.MOUSE_MOVE, mouseNotOverPie);
			addEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
		}
		
		private function addedToStageListener(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
			
			// Create an invisible fill covering the entire stage, in order to intercept all mouse-clicks
			graphics.beginFill(0, 0);
			graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			addEventListener(MouseEvent.CLICK, dismiss);
			
		}
		
		private function createPie():void {
			pie = new Sprite();
			pie.graphics.lineStyle(1, PIE_BORDER_COLOR, PIE_ALPHA);
			pie.graphics.beginFill(PIE_COLOR, PIE_ALPHA);
			pie.graphics.drawCircle(0, 0, RADIUS);
			pie.graphics.drawCircle(0, 0, RADIUS / 2);
			pie.graphics.endFill();
			
			sliceDegrees = 360 / slices.length;
			facingFirstSliceEdge = (CENTER_OF_FIRST_SLICE - (sliceDegrees / 2) + 360) % 360;
			
			for (var i:int = 0; i < slices.length; ++i) {
				var edgeOuter:Point = Util.pointOnCircleFromFacing(RADIUS, facingFirstSliceEdge + i*sliceDegrees);
				var edgeInner:Point = Util.pointOnCircleFromFacing(RADIUS / 2, facingFirstSliceEdge + i*sliceDegrees);
				pie.graphics.moveTo(edgeInner.x, edgeInner.y);
				pie.graphics.lineTo(edgeOuter.x, edgeOuter.y);
				
				var iconCenter:Point = Util.pointOnCircleFromFacing(RADIUS * 0.75, facingFirstSliceEdge + (i + 0.5) * sliceDegrees);
				var bitmap:Bitmap = new Bitmap(slices[i].icon);
				bitmap.x = iconCenter.x - ICON_SIZE / 2;
				bitmap.y = iconCenter.y - ICON_SIZE / 2;
				bitmap.alpha = ICON_ALPHA;
				pie.addChild(bitmap);
			}
		}
		
		private function dismiss(event:MouseEvent):void {
			cleanup();
		}
		
		private function clickedPie(event:MouseEvent):void {
			var sliceIndex:int = sliceIndexFromMouseEvent(event);
			if (slices[sliceIndex].callback != null) {
				slices[sliceIndex].callback();
			} else {
				Alert.show("Clicked slice " + sliceIndex + ", no code attached.");
			}
			cleanup();
		}
		
		private function mouseOverPie(event:MouseEvent):void {
			var sliceIndex:int = sliceIndexFromMouseEvent(event);
			var newOverIcon:Bitmap = Bitmap(pie.getChildAt(sliceIndex));
			adjustOverIcon(newOverIcon);
			event.stopPropagation();
		}
		
		private function mouseNotOverPie(event:MouseEvent):void {
			adjustOverIcon(null);
		}
		
		private function adjustOverIcon(newOverIcon:Bitmap):void {
			if (newOverIcon != overIcon) {
				if (overIcon != null) {
					overIcon.alpha = ICON_ALPHA;
				}
				if (newOverIcon != null) {
					newOverIcon.alpha = 1;
				}
				overIcon = newOverIcon;
			}
		}
		
		private function sliceIndexFromMouseEvent(event:MouseEvent):int {
			var clickFacing:int = Util.findRotFacingVector(new Point(event.localX, event.localY));
			var offsetFromFirstEdge:int = (clickFacing - facingFirstSliceEdge + 360) % 360;
			return offsetFromFirstEdge / sliceDegrees;
		}
		
		public function cleanup():void {
			if (parent != null) {
				parent.removeChild(this);
			}
			removeEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
			removeEventListener(MouseEvent.CLICK, dismiss);	
			removeEventListener(MouseEvent.MOUSE_MOVE, mouseNotOverPie);
			pie.removeEventListener(MouseEvent.CLICK, clickedPie);
			pie.removeEventListener(MouseEvent.MOUSE_MOVE, mouseOverPie);
		}
		
	}

}