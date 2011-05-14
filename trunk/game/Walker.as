package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.common.Prop;
	import angel.common.WalkerImage;
	import angel.game.brain.BrainFidget;
	import angel.game.brain.BrainFollow;
	import angel.game.brain.BrainPatrol;
	import angel.game.brain.BrainWander;
	import angel.game.brain.CombatBrainPatrolRun;
	import angel.game.brain.CombatBrainPatrolSprint;
	import angel.game.brain.CombatBrainPatrolWalk;
	import angel.game.brain.CombatBrainWander;
	import angel.game.combat.Gun;
	import angel.game.conversation.ConversationData;
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	public class Walker extends ComplexEntity {
		
		private var walkerImage:WalkerImage;
		private var deathTimer:Timer;
		private var solidnessWhenAlive:uint;
		
		private static const DEATH_DURATION:int = 500; // milliseconds
		private static const WALK_FRAMES:Vector.<int> = Vector.<int>([WalkerImage.LEFT, WalkerImage.STAND,
			WalkerImage.RIGHT, WalkerImage.STAND, WalkerImage.LEFT, WalkerImage.STAND, WalkerImage.RIGHT, WalkerImage.STAND]);
		
		// id is for debugging use only
		public function Walker(walkerImage:WalkerImage, id:String="") {
			this.walkerImage = walkerImage;
			facing = WalkerImage.FACE_CAMERA;
			super(new Bitmap(walkerImage.bitsFacing(facing)), id);
			this.maxHealth = this.currentHealth = walkerImage.health;
			myDisplayName = walkerImage.displayName;
			setMovePoints(walkerImage.movePoints);
			inventory.add(new Gun(walkerImage.damage));
			solidness = solidnessWhenAlive = Prop.DEFAULT_CHARACTER_SOLIDITY;
		}

		override protected function adjustImageForMove():void {
			Assert.assertTrue(currentHealth >= 0, "Dead entity " + aaId + " moving");
			stopDying();
			var step:int;
			if (coordsForEachFrameOfMove == null) {
				step = WalkerImage.STAND;
			} else {
				var foot:int = frameOfMove * WALK_FRAMES.length / coordsForEachFrameOfMove.length;
				step = WALK_FRAMES[foot];
			}
			imageBitmap.bitmapData = walkerImage.bitsFacing(facing, step);
		}
		override public function turnToFacing(newFacing:int):void {
			Assert.assertTrue(currentHealth >= 0, "Dead entity " + aaId + " turning");
			stopDying();
			super.turnToFacing(newFacing);
			imageBitmap.bitmapData = walkerImage.bitsFacing(facing);
		}
		
		override public function initHealth():void {
			super.initHealth();
			stopDying();
			solidness = solidnessWhenAlive;
			imageBitmap.bitmapData = walkerImage.bitsFacing(facing); // stand back up if we were dead
		}
		
		private function stopDying():void {
			if (deathTimer != null) {
				deathTimer.stop();
			}
		}
		
		// Start death animation unless it's already in progress, in which case just let it continue
		// NOTE: this is a real-time animation; it continues even when game pauses.
		override public function startDeathAnimation():void {
			if (deathTimer == null) {
				imageBitmap.bitmapData = walkerImage.bitsFacing(WalkerImage.FACE_DYING, 0);
				deathTimer = new Timer(DEATH_DURATION / 2, 2);
				deathTimer.addEventListener(TimerEvent.TIMER, advanceDeathAnimation);
				deathTimer.start();
			}
		}
		
		private function advanceDeathAnimation(event:TimerEvent):void {
			imageBitmap.bitmapData = walkerImage.bitsFacing(WalkerImage.FACE_DYING, deathTimer.currentCount);
			if (deathTimer.currentCount == 2) {
				deathTimer.stop();
				deathTimer.removeEventListener(TimerEvent.TIMER, advanceDeathAnimation);
				deathTimer = null;
			}
		}

		private static const exploreBrain:Object = { fidget:BrainFidget, follow:BrainFollow, patrol:BrainPatrol, wander:BrainWander };
		private static const combatBrain:Object = { patrolWalk:CombatBrainPatrolWalk, patrolRun:CombatBrainPatrolRun, 
		patrolSprint:CombatBrainPatrolSprint, wander:CombatBrainWander };

		public static function exploreBrainClassFromString(brainName:String):Class {
			if ((brainName == null) || (brainName == "")) {
				return null;
			}
			return exploreBrain[brainName];
		}

		public static function combatBrainClassFromString(brainName:String):Class {
			if ((brainName == null) || (brainName == "")) {
				return null;
			}
			return combatBrain[brainName];
		}
		
		public static function createFromRoomContentsXml(walkerXml:XML, version:int, catalog:Catalog):Walker {
			var id:String;
			
			//Delete older version support eventually
			if (version < 1) {
				id = walkerXml;
			} else {
				id = walkerXml.@id
			}
			
			var walker:Walker = new Walker(catalog.retrieveWalkerImage(id), id);
			walker.exploreBrainClass = exploreBrainClassFromString(walkerXml.@explore);
			walker.combatBrainClass = combatBrainClassFromString(walkerXml.@combat);
			walker.exploreBrainParam = walkerXml.@exploreParam;
			walker.combatBrainParam = walkerXml.@combatParam;
			
			walker.setCommonPropertiesFromXml(walkerXml);
			return walker;
		}
		
	} // end class Walker

}