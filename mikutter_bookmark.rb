#-*- coding: utf-8 -*-
require 'pstore'

Plugin.create :bookmark do

  def bookmark_init
    return @@bookmark if defined? @@bookmark
    @@bookmark = PStore.new(File.expand_path(File.join(File.dirname(__FILE__), "bookmark.db")))
    @@bookmark.transaction do
      unless @@bookmark.roots
        @@bookmark[:list] = []
      end
    end
    @@bookmark
  end

  tab :bookmark_tab, 'Bookmark Tab' do
    set_icon File.expand_path(File.join(File.dirname(__FILE__), "icons", "bookmark-view.png"))
    timeline :bookmark_tab
  end

  bookmark_init
  @@bookmark.transaction do
    if @@bookmark[:list] == nil
      @@bookmark[:list] = []
    end
    @@bookmark[:list].sort_by{|time,id| time}.last(200).each do |time, id|
      Thread.new {
        message = Message.findbyid(id)
        timeline(:bookmark_tab) << message if message
      }
    end
  end

  def reload_bookmark
    timeline(:bookmark_tab).clear
    @@bookmark.transaction do
      if @@bookmark[:list] == nil
        @@bookmark[:list] = []
      end
      @@bookmark[:list].sort_by{|time,id| time}.last(200).each do |time, id|
        Thread.new {
          message = Message.findbyid(id)
          timeline(:bookmark_tab) << message if message
        }
      end
    end
  end

  def add_bookmark(message)
    @@bookmark.transaction do
      if @@bookmark[:list].select{ |time, id| id == message.id }.size > 0
        Plugin.call(:update, nil, [Message.new(:message => "Bookmarkに登録済みです", :system => true)])
      else
        @@bookmark[:list] << [Time.now.strftime("%s"), message.id]
        Plugin.call(:update, nil, [Message.new(:message => "Bookmarkに登録しました", :system => true)])
        timeline(:bookmark_tab) << message
      end
    end
  end

  def remove_bookmark(message)
    @@bookmark.transaction do
      if @@bookmark[:list].reject!{|time,id| id == message.id}
        Plugin.call(:update, nil, [Message.new(:message => "Bookmarkから削除しました", :system => true)])
      else
        Plugin.call(:update, nil, [Message.new(:message => "Bookmarkから削除できませんでした", :system => true)])
      end
    end
  end

  command(:add_bookmark,
          name: 'Bookmarkに追加',
          condition: lambda{ |opt| opt.messages.size > 0 },
          visible: true,
          icon: File.expand_path(File.join(File.dirname(__FILE__), "icons", "list-add.png")),
          role: :timeline) do |opt|
    opt.messages.each do |m|
      add_bookmark(m)
    end
  end

  command(:remove_bookmark,
          name: 'Bookmarkから削除',
          condition: lambda{ |opt| opt.messages.size > 0 },
          visible: true,
          icon: File.expand_path(File.join(File.dirname(__FILE__), "icons", "list-remove.png")),
          role: :timeline) do |opt|
    opt.messages.each do |m|
      remove_bookmark(m)
    end
  end

  command(:reload_bookmark,
          name: 'Bookmarkを再読み込み',
          condition: lambda{ |opt| true },
          visible: true,
          icon: File.expand_path(File.join(File.dirname(__FILE__), "icons", "view-refresh.png")),
          role: :window) do |opt|
    reload_bookmark
  end

end
