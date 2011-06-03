package angel.game.test {
	import angel.common.Alert;
	import angel.common.WeaponResource;
	import angel.game.CanBeInInventory;
	import angel.game.combat.Grenade;
	import angel.game.combat.SingleTargetWeapon;
	import angel.game.Inventory;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class InventoryTest {
		
		public function InventoryTest() {
			Autotest.testFunction(pileManagement);
			Autotest.testFunction(weaponEquip);
		}
		
		private function pileManagement():void {
			var inventory:Inventory = new Inventory();
			var dummyWeaponResource:WeaponResource = new WeaponResource();
			var gun1:SingleTargetWeapon = new SingleTargetWeapon(dummyWeaponResource, "xxGun1");
			var gun2:SingleTargetWeapon = new SingleTargetWeapon(dummyWeaponResource, "xxGun2");
			var someGun:SingleTargetWeapon;
			var grenade1:Grenade = Grenade.getCopy();
			var grenade2:Grenade = Grenade.getCopy();
			
			Autotest.assertNotEqual(gun1, gun2, "Argh");
			
			Autotest.assertEqual(inventory.entriesInPileOfStuff(), 0, "Inventory should start empty");
			Autotest.assertEqual(inventory.findFirstMatchingInPileOfStuff(SingleTargetWeapon), null, "Empty inventory shouldn't contain any guns.");
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 0, "With no guns the gun count should be zero.");
			
			inventory.addToPileOfStuff(gun1);
			Autotest.assertEqual(inventory.entriesInPileOfStuff(), 1);
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 1, "Should have exactly one gun.");
			Autotest.assertEqual(inventory.findFirstMatchingInPileOfStuff(SingleTargetWeapon), gun1, "Should have found the gun we added.");
			Autotest.assertNotEqual(inventory.findFirstMatchingInPileOfStuff(SingleTargetWeapon), gun2, "Other gun shouldn't match.");
			Autotest.assertEqual(inventory.findFirstMatchingInPileOfStuff(CanBeInInventory), gun1, "Should be able to search by superclass");
			
			inventory = new Inventory();
			inventory.addToPileOfStuff(gun1);
			inventory.addToPileOfStuff(gun2);
			Autotest.assertEqual(inventory.entriesInPileOfStuff(), 2);
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 2, "Should have two different guns now.");
			someGun = SingleTargetWeapon(inventory.findFirstMatchingInPileOfStuff(SingleTargetWeapon));
			Autotest.assertNotEqual(someGun, null, "Searching for gun should find something.");
			Autotest.assertTrue(((someGun === gun1) || (someGun === gun2)), "Should find one or the other.");
			
			inventory = new Inventory();
			inventory.addToPileOfStuff(gun1, 2);
			inventory.addToPileOfStuff(gun2, 3);
			Autotest.assertEqual(inventory.entriesInPileOfStuff(), 2);
			Autotest.assertEqual(inventory.countSpecificItemInPileOfStuff(gun1), 2);
			Autotest.assertEqual(inventory.countSpecificItemInPileOfStuff(gun2), 3);
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 5);
			
			inventory = new Inventory();
			inventory.addToPileOfStuff(gun1);
			inventory.addToPileOfStuff(gun2);
			inventory.removeAllFromPileOfStuff(gun1);
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 1, "Should have only one gun after removing one.");
			Autotest.assertEqual(inventory.findFirstMatchingInPileOfStuff(SingleTargetWeapon), gun2, "Wrong gun was removed when removing first one.");
			
			inventory = new Inventory();
			inventory.addToPileOfStuff(gun1);
			inventory.addToPileOfStuff(gun2);
			Autotest.assertNoAlert();
			inventory.removeFromPileOfStuff(gun1, 2);
			Autotest.assertAlerted();
			Autotest.clearAlert();
			
			inventory = new Inventory();
			inventory.addToPileOfStuff(gun1);
			Autotest.assertNoAlert();
			inventory.removeAllFromPileOfStuff(gun2);
			Autotest.assertAlerted();
			Autotest.clearAlert();
			
			inventory = new Inventory();
			inventory.addToPileOfStuff(gun1);
			inventory.addToPileOfStuff(gun2);
			inventory.removeAllFromPileOfStuff(gun2);
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 1, "Should have only one gun after removing one.");
			Autotest.assertEqual(inventory.findFirstMatchingInPileOfStuff(SingleTargetWeapon), gun1, "Wrong gun was removed when removing second one.");
			
			inventory = new Inventory();
			inventory.addToPileOfStuff(gun1);
			inventory.addToPileOfStuff(grenade1);
			Autotest.assertEqual(inventory.entriesInPileOfStuff(), 2);
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 1);
			Autotest.assertEqual(inventory.countInPileOfStuff(Grenade), 1);
			inventory.addToPileOfStuff(grenade2);
			Autotest.assertEqual(inventory.entriesInPileOfStuff(), 2, "Grenade is a singleton, shouldn't be able to take additional slots");
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 1);
			Autotest.assertEqual(inventory.countInPileOfStuff(Grenade), 2);
			inventory.addToPileOfStuff(grenade1, 3);
			Autotest.assertEqual(inventory.countInPileOfStuff(Grenade), 5);
			
			Autotest.assertNoAlert()
			inventory.addToPileOfStuff(grenade1, -1);
			Autotest.assertAlerted("Adding less than one item is an error");
			Autotest.clearAlert();
			
			inventory.addToPileOfStuff(gun1);
			inventory.addToPileOfStuff(gun2);
			inventory.removeAllMatchingFromPileOfStuff(SingleTargetWeapon);
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 0);
		}
		
		private function weaponEquip():void {
			var inventory:Inventory = new Inventory();
			var dummyWeaponResource:WeaponResource = new WeaponResource();
			var gun1:SingleTargetWeapon = new SingleTargetWeapon(dummyWeaponResource, "xxGun1");
			var gun2:SingleTargetWeapon = new SingleTargetWeapon(dummyWeaponResource, "xxGun2");
			var grenade1:Grenade = Grenade.getCopy();
			
			Autotest.assertEqual(inventory.mainWeapon(), null);
			Autotest.assertEqual(inventory.offWeapon(), null);
			
			Autotest.assertFalse(inventory.equip(grenade1, Inventory.MAIN_HAND), "Hand slots must be SingleTargetWeapon");
			Autotest.assertEqual(inventory.mainWeapon(), null);
			
			Autotest.assertTrue(inventory.equip(gun1, Inventory.MAIN_HAND), "Put gun in hand slot");
			Autotest.assertEqual(inventory.mainWeapon(), gun1);
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 0);
			
			inventory.unequip(Inventory.MAIN_HAND, true);
			Autotest.assertEqual(inventory.mainWeapon(), null);
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 1);
			
			Autotest.assertTrue(inventory.equipFromPileOfStuff(gun1, Inventory.MAIN_HAND), "Move gun to hand slot from pile");
			Autotest.assertEqual(inventory.mainWeapon(), gun1);
			Autotest.assertEqual(inventory.countInPileOfStuff(SingleTargetWeapon), 0);
			
			Autotest.assertFalse(inventory.equipFromPileOfStuff(gun2, Inventory.MAIN_HAND), "Gun2 wasn't in pile to equip");
			
			Autotest.assertTrue(inventory.equip(gun1, Inventory.MAIN_HAND), "Put gun2 in hand slot");
			Autotest.assertEqual(inventory.mainWeapon(), gun2);
			Autotest.assertEqual(inventory.countSpecificItemInPileOfStuff(gun1), 1, "gun1 should have returned to pile");
			
			Autotest.assertFalse(inventory.equipFromPileOfStuff(gun1, Inventory.OFF_HAND));
			Autotest.assertEqual(inventory.mainWeapon(), gun2);
			Autotest.assertEqual(inventory.offWeapon(), gun1);
		}
		
	}

}