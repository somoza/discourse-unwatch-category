# name: Unwatch Category
# about: Force to Unwatches a category for all the users in a particular group. Based on Watch Category Plugin
# version: 0.3
# authors: Julián Somoza
# url: https://github.com/discourse/discourse-watch-category-mcneel

module ::UnwatchCategory

  def self.unwatch_category!
    groups_cats = {
      "Usuarios" => [ "anuncios-institucionales", "servicios-internos-cab" ]
    }

    groups_cats.each do |group_name, cats|
      cats.each do |cat_slug|

        # If a category is an array, the first value is treated as the top-level category and the second as the sub-category
        if cat_slug.respond_to?(:each)
          category = Category.find_by_slug(cat_slug[1], cat_slug[0])
        else
          category = Category.find_by_slug(cat_slug)
        end
        group = Group.find_by_name(group_name)

        unless category.nil? || group.nil?
          group.users.each do |user|
            unwatched_categories = CategoryUser.lookup(user, :regular).pluck(:category_id)
            CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[:regular], category.id) unless unwatched_categories.include?(category.id)
          end
        end
      end
    end

  end
end

after_initialize do
  module ::UnwatchCategory
    class WatchCategoryJob < ::Jobs::Scheduled
      every 3.hours

      def execute(args)
        UnwatchCategory.unwatch_category!
      end
    end
  end
end
