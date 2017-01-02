//
//  PreviewController.swift
//  FoodTracker
//
//  Created by panzhansheng on 2016/10/2.
//  Copyright © 2016年 idup. All rights reserved.
//

import UIKit

class PreviewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var restaurantLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    var food: Food?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let food = food{
            nameLabel.text = food.name
            phoneLabel.text = food.phone
            restaurantLabel.text = food.restaurant
            imageView.image = food.photo
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
