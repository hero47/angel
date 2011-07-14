package angel.game.combat {
	import angel.common.Assert;
	import angel.common.Floor;
	import angel.common.Prop;
	import angel.common.Util;
	import angel.common.WeaponResource;
	import angel.game.ComplexEntity;
	import angel.game.Icon;
	import angel.game.inventory.CanBeInInventory;
	import angel.game.Room;
	import angel.game.Settings;
	import angel.game.TimedSprite;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormatAlign;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ThrownWeapon extends WeaponBase implements ICombatUseFromPile {
		
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
		
		public function ThrownWeapon(resource:WeaponResource, id:String) {
			if (resource != null) { // called with null when cloning
				super(resource, id);
			}
		}
		
		/* INTERFACE angel.game.combat.IWeapon */
		
		public function stacksWith(other:CanBeInInventory):Boolean {
			var otherWeapon:ThrownWeapon = other as ThrownWeapon;
			return ((otherWeapon != null) && (otherWeapon.id == id));
		}
		
		public function useOn(user:ComplexEntity, target:Object):void {
			if (target is Point) {
				throwAt(user, Point(target));
			} else {
				Assert.fail("Bad target type " + target + " in " + this);
			}
		}
		
		// per Wm: uses two actions, but someone with only one action can still throw;
		// the UI/brain will need to enforce this.
		private function throwAt(shooter:ComplexEntity, targetLocation:Point):void {
			shooter.turnToFaceTile(targetLocation);
			shooter.actionsRemaining -= 2;
			
			shooter.inventory.removeFromPileOfStuff(this, 1);
			new ThrowAnimation(shooter.room, shooter, targetLocation, deliverPayloadAt);
		}
		
		protected function deliverPayloadAt(room:Room, shooter:ComplexEntity, location:Point):void {
			explodeAt(room, location, baseDamage);
		}
		
		public static function explodeAt(room:Room, location:Point, baseDamage:int):void {
			var temporaryGrenadeExplosionGraphic:TimedSprite = new TimedSprite(Settings.FRAMES_PER_SECOND);	
			
			// Process all of outer ring first, so things in inner ring will provide blast shadow even if they are destroyed
			applyGrenadeToOffsets(room, location, grenadeOuter, baseDamage / 2, temporaryGrenadeExplosionGraphic);
			applyGrenadeToOffsets(room, location, grenadeInner, baseDamage, temporaryGrenadeExplosionGraphic);
			room.addChild(temporaryGrenadeExplosionGraphic);
			
			room.snapToCenter(location);
		}
		
		private static function applyGrenadeToOffsets(room:Room, targetLocation:Point, offsets:Vector.<Point>, damagePoints:int, graphic:Sprite):void {
			for each (var offset:Point in offsets) {
				applyGrenadeToLocation(room, targetLocation, targetLocation.add(offset), damagePoints, graphic);
			}
		}
		
		private static function applyGrenadeToLocation(room:Room, center:Point, location:Point, damagePoints:int, graphic:Sprite):void {
			if ((location.x < 0) || (location.x >= room.size.x) || (location.y < 0) || (location.y >= room.size.y)) {
				return;
			}
			if ((Util.chessDistance(center, location) > 1) && !Util.lineUnblocked(room.blocksThrown, center, location)) {
				// CONSIDER: replace this with just "return" if we don't want graphic on shadowed squares
				damagePoints = 0;
			}
			room.forEachEntityIn(location, function(entity:ComplexEntity):void {
				entity.takeDamage(damagePoints, false);
				trace(entity.aaId, "hit by grenade for", damagePoints);
			}, filterIsActive);
			
			var tileCenter:Point = Floor.centerOf(location);
			var num:TextField = Util.textBox(String(damagePoints), 0, 30, TextFormatAlign.LEFT, false, 0xff0000);
			num.autoSize = TextFieldAutoSize.LEFT;
			num.x = tileCenter.x - num.width / 2;
			num.y = tileCenter.y - num.height / 2;
			graphic.addChild(num);
		}	
		
		private static function filterIsActive(prop:Prop):Boolean {
			return ((prop is ComplexEntity) && ComplexEntity(prop).isActive());
		}
		
	}

}