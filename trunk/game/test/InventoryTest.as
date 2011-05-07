package angel.game.test {
	import angel.common.Alert;
	import angel.game.CanBeInInventory;
	import angel.game.combat.Grenade;
	import angel.game.combat.Gun;
	import angel.game.Inventory;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class InventoryTest {
		
		public function InventoryTest() {
			var inventory:Inventory = new Inventory();
			var gun1:Gun = new Gun(10);
			var gun2:Gun = new Gun(20);
			var someGun:Gun;
			var grenade1:Grenade = Grenade.getCopy();
			var grenade2:Grenade = Grenade.getCopy();
			
			Autotest.assertNotEqual(gun1, gun2, "Argh");
			
			Autotest.assertEqual(inventory.slotsUsed(), 0, "Inventory should start empty");
			Autotest.assertEqual(inventory.findA(Gun), null, "Empty inventory shouldn't contain any guns.");
			Autotest.assertEqual(inventory.count(Gun), 0, "With no guns the gun count should be zero.");
			
			inventory.add(gun1);
			Autotest.assertEqual(inventory.slotsUsed(), 1);
			Autotest.assertEqual(inventory.count(Gun), 1, "Should have exactly one gun.");
			Autotest.assertEqual(inventory.findA(Gun), gun1, "Should have found the gun we added.");
			Autotest.assertNotEqual(inventory.findA(Gun), gun2, "Other gun shouldn't match.");
			Autotest.assertEqual(inventory.findA(CanBeInInventory), gun1, "Should be able to search by superclass");
			
			inventory = new Inventory();
			inventory.add(gun1);
			inventory.add(gun2);
			Autotest.assertEqual(inventory.slotsUsed(), 2);
			Autotest.assertEqual(inventory.count(Gun), 2, "Should have two different guns now.");
			someGun = Gun(inventory.findA(Gun));
			Autotest.assertNotEqual(someGun, null, "Searching for gun should find something.");
			Autotest.assertTrue(((someGun === gun1) || (someGun === gun2)), "Should find one or the other.");
			
			inventory = new Inventory();
			inventory.add(gun1, 2);
			inventory.add(gun2, 3);
			Autotest.assertEqual(inventory.slotsUsed(), 2);
			Autotest.assertEqual(inventory.countSpecificItem(gun1), 2);
			Autotest.assertEqual(inventory.countSpecificItem(gun2), 3);
			Autotest.assertEqual(inventory.count(Gun), 5);
			
			inventory = new Inventory();
			inventory.add(gun1);
			inventory.add(gun2);
			inventory.removeAll(gun1);
			Autotest.assertEqual(inventory.count(Gun), 1, "Should have only one gun after removing one.");
			Autotest.assertEqual(inventory.findA(Gun), gun2, "Wrong gun was removed when removing first one.");
			
			inventory = new Inventory();
			inventory.add(gun1);
			inventory.add(gun2);
			Autotest.assertNoAlert();
			inventory.remove(gun1, 2);
			Autotest.assertAlerted();
			Autotest.clearAlert();
			
			inventory = new Inventory();
			inventory.add(gun1);
			Autotest.assertNoAlert();
			inventory.removeAll(gun2);
			Autotest.assertAlerted();
			Autotest.clearAlert();
			
			inventory = new Inventory();
			inventory.add(gun1);
			inventory.add(gun2);
			inventory.removeAll(gun2);
			Autotest.assertEqual(inventory.count(Gun), 1, "Should have only one gun after removing one.");
			Autotest.assertEqual(inventory.findA(Gun), gun1, "Wrong gun was removed when removing second one.");
			
			inventory = new Inventory();
			inventory.add(gun1);
			inventory.add(grenade1);
			Autotest.assertEqual(inventory.slotsUsed(), 2);
			Autotest.assertEqual(inventory.count(Gun), 1);
			Autotest.assertEqual(inventory.count(Grenade), 1);
			inventory.add(grenade2);
			Autotest.assertEqual(inventory.slotsUsed(), 2, "Grenade is a singleton, shouldn't be able to take additional slots");
			Autotest.assertEqual(inventory.count(Gun), 1);
			Autotest.assertEqual(inventory.count(Grenade), 2);
			inventory.add(grenade1, 3);
			Autotest.assertEqual(inventory.count(Grenade), 5);
			
			Autotest.assertNoAlert()
			inventory.add(grenade1, -1);
			Autotest.assertAlerted("Adding less than one item is an error");
			Autotest.clearAlert();
		}
		
	}

}