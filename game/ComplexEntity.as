package angel.game {
	import angel.common.Catalog;
	import angel.common.CharacterStats;
	import angel.common.IEntityAnimation;
	import angel.common.Prop;
	import angel.common.RoomContentResource;
	import angel.common.Tileset;
	import angel.common.Util;
	import angel.game.brain.IBrain;
	import angel.game.brain.UtilBrain;
	import angel.game.combat.Gun;
	import angel.game.combat.IWeapon;
	import angel.game.combat.RoomCombat;
	import angel.game.event.EntityQEvent;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormatAlign;

	// A physical object in the game world -- we aren't yet distinguishing between pc/npc/mobile/immobile.
	
	public class ComplexEntity extends SimpleEntity {
		// Facing == rotation/45 if we were in a top-down view.
		// This will make it convenient if we ever want to determine facing from actual angles
		public static const FACE_CAMERA:int = 1;
		
		private static const TEXT_OVER_HEAD_HEIGHT:int = 20;
		
		// Entity stats!
		// CONSIDER: Initial values for some of these come from a CharacterStats. I could have a CharacterStats embedded
		// here rather than individual variables for the ones that overlap, but currently (5/15/11) that's only two.
		protected var myDisplayName:String;
		public var maxHealth:int = 1;
		public var currentHealth:int;
		public var actionsRemaining:int;
		public var hasCoverFrom:Vector.<ComplexEntity> = new Vector.<ComplexEntity>();
		
		public var exploreBrainClass:Class;
		public var exploreBrainParam:String;
		public var combatBrainClass:Class;
		public var combatBrainParam:String;
		// This has no type yet because we aren't doing anything with it yet.  Eventually it will probably be an interface.
		public var brain:IBrain;
		public var inventory:Inventory = new Inventory();
		
		private var playerControlled:Boolean;
		
		public var marker:DisplayObject; // if non-null, drawn on decorations layer centered directly under me
		private var textOverHead:TextField;
		protected var facing:int;
		private var solidnessWhenAlive:uint;
		
		public var movement:EntityMovement;
		private var animation:IEntityAnimation;
		
		public function ComplexEntity(resource:RoomContentResource, id:String = "") {
			super(new Bitmap(resource.standardImage()), resource.solidness, id);
			
			var characterStats:CharacterStats = resource.characterStats;
			maxHealth = currentHealth = characterStats.health;
			myDisplayName = characterStats.displayName;
			initMovement(characterStats.movePoints, characterStats.maxGait);
			if (characterStats.damage > 0) {
				inventory.add(new Gun(characterStats.damage));
			}
			solidness = solidnessWhenAlive = resource.solidness;
			
			facing = FACE_CAMERA;
			animation = new resource.animationData.animationClass(resource.animationData, this.imageBitmap);
		}
		
		public static function createFromRoomContentsXml(walkerXml:XML, version:int, catalog:Catalog):ComplexEntity {
			var id:String;
			
			//Delete older version support eventually
			if (version < 1) {
				id = walkerXml;
			} else {
				id = walkerXml.@id
			}
			
			var resource:RoomContentResource = catalog.retrieveCharacterResource(id);
			if (resource == null) { // Catalog had something with this id that's not a character resource
				return null;
			}
			
			var entity:ComplexEntity = new ComplexEntity(resource, id);
			entity.setBrain(true, UtilBrain.exploreBrainClassFromString(walkerXml.@explore), walkerXml.@exploreParam);
			entity.setBrain(false, UtilBrain.combatBrainClassFromString(walkerXml.@combat), walkerXml.@combatParam);
			entity.setCommonPropertiesFromXml(walkerXml);
			return entity;
		}
		
		override public function detachFromRoom():void {
			// NOTE: if entity is a pc, a reference to it will still exist through the player list in Settings.
			if (movement != null) {
				movement.detachFromRoom();
			}
			super.detachFromRoom();
		}
		
		override public function set x(value:Number):void {
			super.x = value;
			if (marker != null) {
				marker.x = this.x + this.width / 2;
			}
		}
		
		override public function set y(value:Number):void {
			super.y = value;
			if (marker != null) {
				marker.y = this.y + Tileset.TILE_HEIGHT / 2;
			}
		}
		
		override public function get displayName():String {
			return myDisplayName;
		}
		
		public function canMove():Boolean {
			//UNDONE: movement can't be null yet, see note in initMovement
			return ((movement != null) && (movement.maxDistanceForGait() > 0));
			//return (movement != null);
		}
		
		public function moving():Boolean {
			return ((movement != null) && movement.moving());
		}
		
		// CONSIDER: maxGait is a hack, it will probably eventually be based on armor
		public function initMovement(points:int, maxGait:int):void {
			//UNDONE: Currently (5/20/11) we break horribly if movement is null.  Combat phase transition requires
			//getting a EntityEvent.MOVED, which is generated by the movement code.  I'm seriously considering
			//ripping out the current event-driven phase transitions and replacing with a state machine called
			//on enterFrame; if so, I should be able to get rid of that dependency.
			/*
			if (points == 0) {
				if (movement != null) {
					movement.cleanup();
					movement = null;
				}
			} else {
			*/
				if (movement == null) {
					movement = new EntityMovement(this, points, maxGait);
				} else {
					movement.setMovePoints(points);
				}
			/*
			}
			*/
		}
		
		public function attachMarker(newMarker:DisplayObject):void {
			if (marker != null) {
				removeMarker();
			}
			marker = newMarker;
			room.decorationsLayer.addChild(marker);
			marker.x = this.x + this.width / 2;
			marker.y = this.y + Tileset.TILE_HEIGHT/2;
		}
		
		public function removeMarker():void {
			if (marker != null) {
				room.decorationsLayer.removeChild(marker);
				marker = null;
			}
		}
		
		//NOTE: set brain classes and anything they will need for instantiation before calling.
		public function changePlayerControl(willBePc:Boolean):void {
			if (playerControlled == willBePc) {
				return;
			}
			playerControlled = willBePc;
			if (movement != null) {
				movement.setSpeeds(playerControlled);
			}
			adjustBrainForRoomMode(room.mode);
			if (room.mode != null) {
				room.mode.playerControlChanged(this, playerControlled);
			}
			Settings.gameEventQueue.dispatch(new EntityQEvent(this, EntityQEvent.CHANGED_FACTION));
		}
		
		public function get isPlayerControlled():Boolean {
			return (playerControlled || Settings.controlEnemies);
		}
		
		public function get isReallyPlayer():Boolean {
			return playerControlled;
		}
						
		public function isEnemy():Boolean {
			//CONSIDER: is this true, or will we want to have civilians with combat behavior that are untargetable?
			return (!playerControlled && (combatBrainClass != null) && (currentHealth > 0));
		}
		
		public function isAlive():Boolean {
			return (currentHealth > 0);
		}
		
		public function canBeActiveInCombat():Boolean {
			return isPlayerControlled || isEnemy();
		}
		
		public function setBrain(forExplore:Boolean, newBrainClass:Class, newParam:String):void {
			if (forExplore) {
				exploreBrainClass = newBrainClass;
				exploreBrainParam = (newBrainClass == null ? null : newParam);
				if ((room != null) && (room.mode is RoomExplore)) {
					adjustBrainForRoomMode(room.mode);
				}
			} else {
				combatBrainClass = newBrainClass;
				combatBrainParam = (newBrainClass == null ? null : newParam);
				if ((room != null) && (room.mode is RoomCombat)) {
					adjustBrainForRoomMode(room.mode);
				}
			}
		}
		
		public function adjustBrainForRoomMode(mode:IRoomMode):void {
			if (brain != null) {
				brain.cleanup();
			}
			
			if ((mode is RoomCombat) && (combatBrainClass != null)) {
				brain = new combatBrainClass(this, mode, combatBrainParam);
			} else if ((mode is RoomExplore) && (exploreBrainClass != null)) {
				brain = new exploreBrainClass(this, mode, exploreBrainParam);
			} else {
				brain = null;
			}
		}
		
		public function percentOfFullDamageDealt():int {
			return 100 - (movement == null ? 0 : Settings.speedPenalties[movement.mostRecentGait]);
		}
		
		public function damagePercentAfterSpeedApplied():int {
			return 100 - (movement == null ? 0 : Settings.speedDefenses[movement.mostRecentGait]);
		}
		
		public function takeDamage(baseDamage:int, speedReducesDamage:Boolean, extraDamageReductionPercent:int = 0):void {
			if (speedReducesDamage) {
				baseDamage = baseDamage * damagePercentAfterSpeedApplied() / 100;
			}
			if (extraDamageReductionPercent > 0) {
				baseDamage = baseDamage * (100 - extraDamageReductionPercent) / 100;
			}
			currentHealth -= baseDamage;
			trace(aaId, "damaged for", baseDamage, ", health now", currentHealth);
			setTextOverHead(String(currentHealth));
			if (currentHealth > 0) {
				Settings.gameEventQueue.dispatch(new EntityQEvent(this, EntityQEvent.HEALTH_CHANGE));
			} else {
				solidness ^= Prop.TALL; // Dead entities are short, by fiat.
				startDeathAnimation();
				Settings.gameEventQueue.dispatch(new EntityQEvent(this, EntityQEvent.DEATH));
			}
		}
		
		// Reset health at start and end of combat.
		public function initHealth():void {
			currentHealth = maxHealth;
			animation.turnToFacing(facing); // stands back up if we were dead
			solidness = solidnessWhenAlive;
		}
		
		public function setTextOverHead(value:String):void {
			if ((value == null) && (textOverHead != null)) {
				textOverHead.visible = false;
			} else if (value != null) {
				if (textOverHead == null) {
					textOverHead = Util.textBox("", Prop.WIDTH, TEXT_OVER_HEAD_HEIGHT, TextFormatAlign.CENTER);
					textOverHead.background = true;
					textOverHead.autoSize = TextFieldAutoSize.CENTER;
					textOverHead.y = imageBitmap.y - TEXT_OVER_HEAD_HEIGHT - 2;
					addChild(textOverHead);
				}
				textOverHead.visible = true;
				textOverHead.text = value;
			}
		}
				
		public function startDeathAnimation():void {
			animation.startDeathAnimation();
		}
		
		public function adjustImageForMove(frameOfMove:int, totalFramesInMove:int):void {
			animation.adjustImageForMove(facing, frameOfMove, totalFramesInMove);
		}
		
		public function turnToFacing(newFacing:int):void {
			facing = newFacing;
			animation.turnToFacing(facing);
		}
		
		// Turn to the facing that closest approximates that direction
		public function turnToFaceTile(loc:Point):void {
			var angle:int = Util.findRotFacingVector(loc.subtract(myLocation)) + 360 + 22;
			turnToFacing((angle / 45) % 8);
		}
		
		public function centerRoomOnMe():void {
			room.x = (stage.stageWidth / 2) - this.x - this.width/2;
			room.y = (stage.stageHeight / 2) - this.y - this.height/2;
		}
		
		// If we're talking real world, this makes no sense -- cover would be directional, and we'd have to talk about
		// cover from a particular enemy.  Wm wants this move-to-shoot-from-cover thing to be available whenever you're
		// next to a "tall" blocker, regardless of whether there are even any enemies around at all, so...
		public function hasCover():Boolean {
			for each (var toNeighbor:Point in Pathfinder.neighborCheck) {
				var xNext:int = toNeighbor.x + myLocation.x;
				var yNext:int = toNeighbor.y + myLocation.y;
				var neighbor:Point = myLocation.add(toNeighbor);
				if ((xNext >= 0) && (xNext < room.size.x) && (yNext >= 0) && (yNext < room.size.y) && 
							room.blocksSight(xNext, yNext)) {
					return true;
				}
			}
			return false;
		}
		
		public function hasAWeapon():Boolean {
			return inventory.findA(IWeapon) != null;
		}
		
		// Eventually entities will be able to switch between different weapons
		public function currentGun():Gun {
			return inventory.findA(Gun);
		}
		
		public function fireCurrentGunAt(target:ComplexEntity, extraDamageReductionPercent:int = 0):void {
			var gun:Gun = currentGun();
			if (gun != null) {
				gun.fire(this, target, extraDamageReductionPercent);
			}
		}
		
	} // end class ComplexEntity

}
