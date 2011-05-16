package angel.game.combat {
	import angel.common.Assert;
	import angel.common.Floor;
	import angel.common.Prop;
	import angel.common.Util;
	import angel.game.CanBeInInventory;
	import angel.game.ComplexEntity;
	import angel.game.Room;
	import angel.game.Settings;
	import angel.game.TimedSprite;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormatAlign;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	 // This may become an interface once we have more types of area weapons, or the others may extend it
	public class Grenade implements CanBeInInventory {
		
		private static const singleton:Grenade = new Grenade();
		
		private static const grenadeInner:Vector.<Point> = Vector.<Point>([
				new Point(0,0),
				new Point(1, 0), new Point(0, 1), new Point(0, -1), new Point( -1, 0),
				new Point(1, 1), new Point(1, -1), new Point( -1, -1), new Point( -1, 1)
			]);
		private static const grenadeOuter:Vector.<Point> = Vector.<Point>([
				new Point(-2,-2), new Point(-2,-1), new Point(-2,0), new Point(-2,1), new Point(-2,2),
				new Point(-1, -2), new Point( -1, 2),
				new Point(0, -2), new Point(0, 2),
				new Point(1, -2), new Point(1, 2),
				new Point(2,-2), new Point(2,-1), new Point(2,0), new Point(2,1), new Point(2,2)
			]);
		
		public function Grenade() {
			Assert.assertTrue(singleton == null, "Singleton -- need to use getCopy");
		}
		
		public static function getCopy():Grenade {
			return singleton;
		}
		
		public function get displayName():String {
			return "Grenade(s), standard issue";
		}
		
		public function throwAt(shooter:ComplexEntity, targetLocation:Point):void {
			shooter.turnToFaceTile(targetLocation);
			--shooter.actionsRemaining;
			shooter.inventory.remove(this, 1);
			//UNDONE animate grenade moving through air?
			
			var temporaryGrenadeExplosionGraphic:TimedSprite = new TimedSprite(Settings.FRAMES_PER_SECOND);	
			
			// Process all of outer ring first, so things in inner ring will provide blast shadow even if they are destroyed
			applyGrenadeToOffsets(shooter.room, targetLocation, grenadeOuter, Settings.grenadeDamage / 2, temporaryGrenadeExplosionGraphic);
			applyGrenadeToOffsets(shooter.room, targetLocation, grenadeInner, Settings.grenadeDamage, temporaryGrenadeExplosionGraphic);
			shooter.room.addChild(temporaryGrenadeExplosionGraphic);
			
			shooter.room.snapToCenter(targetLocation);
		}
		
		private function applyGrenadeToOffsets(room:Room, targetLocation:Point, offsets:Vector.<Point>, damagePoints:int, graphic:Sprite):void {
			for each (var offset:Point in offsets) {
				applyGrenadeToLocation(room, targetLocation, targetLocation.add(offset), damagePoints, graphic);
			}
		}
		
		private function applyGrenadeToLocation(room:Room, center:Point, location:Point, damagePoints:int, graphic:Sprite):void {
			if ((location.x < 0) || (location.x >= room.size.x) || (location.y < 0) || (location.y >= room.size.y)) {
				return;
			}
			if ((Util.chessDistance(center, location) > 1) && !Util.lineUnblocked(room.blocksGrenade, center, location)) {
				// CONSIDER: replace this with just "return" if we don't want graphic on shadowed squares
				damagePoints = 0;
			}
			room.forEachEntityIn(location, function(entity:ComplexEntity):void {
				entity.takeDamage(damagePoints, false);
				trace(entity.aaId, "hit by grenade for", damagePoints);
			}, filterIsAlive);
			
			var tileCenter:Point = Floor.centerOf(location);
			var num:TextField = Util.textBox(String(damagePoints), 0, 30, TextFormatAlign.LEFT, false, 0xff0000);
			num.autoSize = TextFieldAutoSize.LEFT;
			num.x = tileCenter.x - num.width / 2;
			num.y = tileCenter.y - num.height / 2;
			graphic.addChild(num);
		}	
		
		private function filterIsAlive(prop:Prop):Boolean {
			return ((prop is ComplexEntity) && ComplexEntity(prop).currentHealth > 0);
		}
		
	}

}