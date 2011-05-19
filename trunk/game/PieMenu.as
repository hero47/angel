package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Util;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class PieMenu extends Sprite {
		
		private static const RADIUS:int = 80;
		private static const PIE_COLOR:uint = 0x888888;
		private static const PIE_BORDER_COLOR:uint = 0xcccccc;
		private static const PIE_ALPHA:Number = 0.5;
		private static const ICON_ALPHA:Number = 1;
		private static const CENTER_OF_FIRST_SLICE:int = 180;
		public static const ICON_SIZE:int = 28; // square
		
		private var slices:Vector.<PieSlice>;
		private var callbackAfterClose:Function;
		private var pie:Sprite;
		private var facingFirstSliceEdge:int;
		private var sliceDegrees:int;
		
		private var overIcon:Bitmap;
		
		public function PieMenu(centerX:int, centerY:int, slices:Vector.<PieSlice>, callbackAfterClose:Function = null) {
			this.slices = slices;
			this.callbackAfterClose = callbackAfterClose;
			Assert.assertTrue(slices != null && slices.length > 0, "Pie menu missing data");
			
			createPie();
			pie.x = centerX;
			pie.y = centerY;
			addChild(pie);
			
			pie.addEventListener(MouseEvent.CLICK, clickedPie);
			pie.addEventListener(MouseEvent.MOUSE_MOVE, mouseOverPie);
			
			addEventListener(MouseEvent.CLICK, clickedAnywhere);
			addEventListener(MouseEvent.MOUSE_MOVE, mouseAnywhere);
			addEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
		}
		
		private function addedToStageListener(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
			
			// Create an invisible fill covering the entire stage, in order to intercept all mouse-clicks
			graphics.beginFill(0, 0);
			graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
		}
		
		public function cleanup():void {
			if (parent != null) {
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
				parent.removeChild(this);
			}
			removeEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
			removeEventListener(MouseEvent.CLICK, clickedAnywhere);	
			removeEventListener(MouseEvent.MOUSE_MOVE, mouseAnywhere);
			pie.removeEventListener(MouseEvent.CLICK, clickedPie);
			pie.removeEventListener(MouseEvent.MOUSE_MOVE, mouseOverPie);
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
		
		private function dismiss():void {
			cleanup();
			if (callbackAfterClose != null) {
				callbackAfterClose();
			}
		}
		
		private function clickedAnywhere(event:MouseEvent):void {
			if (event.target == this) {
				//Dismiss if we're only over the PieMenu (which occupies the full stage), but
				//not over the sprite that forms the visual menu. Clicks on the sprite are
				//handled by the pie listener.
				dismiss();
			}
		}
		
		private function keyDownListener(event:KeyboardEvent):void {
			if (event.keyCode == Keyboard.BACKSPACE) {
				dismiss();
			}
		}
		
		private function clickedPie(event:MouseEvent):void {
			var sliceIndex:int = sliceIndexFromMouseEvent(event);
			if (slices[sliceIndex].callback != null) {
				slices[sliceIndex].callback();
				dismiss();
			}
			// Wm wants to put "informational" pie slices that have no callback and don't dismiss the menu
			// if clicked.  I think not dismissing is a bad design choice, but doing it under protest.
		}
		
		private function mouseOverPie(event:MouseEvent):void {
			var sliceIndex:int = sliceIndexFromMouseEvent(event);
			var newOverIcon:Bitmap = Bitmap(pie.getChildAt(sliceIndex));
			adjustOverIcon(newOverIcon, slices[sliceIndex].text);
		}
		
		private function mouseAnywhere(event:MouseEvent):void {
			if (event.target == this) {
				//De-hilight the icon if we're only over the PieMenu (which occupies the full stage), but
				//not over the sprite that forms the visual menu
				adjustOverIcon();
			}
		}
		
		private function adjustOverIcon(newOverIcon:Bitmap = null, popupText:String = ""):void {
			/*
			if (newOverIcon != overIcon) {
				if (overIcon != null) {
					overIcon.alpha = ICON_ALPHA;
				}
				if (newOverIcon != null) {
					newOverIcon.alpha = 1;
				}
				overIcon = newOverIcon;
			}
			*/
			if (newOverIcon != overIcon) {
				if (overIcon != null) {
					ToolTip.removeToolTip();
				}
				if (newOverIcon != null) {
					ToolTip.displayToolTip(pie, popupText, newOverIcon.x + newOverIcon.width, newOverIcon.y);
				}
				overIcon = newOverIcon;
				
			}
		}
		
		private function sliceIndexFromMouseEvent(event:MouseEvent):int {
			var clickFacing:int = Util.findRotFacingVector(new Point(event.localX, event.localY));
			var offsetFromFirstEdge:int = (clickFacing - facingFirstSliceEdge + 360) % 360;
			return offsetFromFirstEdge / sliceDegrees;
		}
		
	}

}