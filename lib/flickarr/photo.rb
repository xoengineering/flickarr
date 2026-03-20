require 'date'
require 'slugify'

module Flickarr
  class Photo
    attr_reader :description,
                :extension,
                :id,
                :media,
                :tags,
                :title

    def initialize info:, sizes:
      @id          = info.id
      @description = info.description.to_s
      @extension   = info.originalformat.to_s
      @media       = info.media.to_s
      @tags        = info.tags.tag.map(&:_content)
      @title       = info.title.to_s

      @dates          = info.dates
      @sizes          = sizes
    end

    def basename
      s = slug
      s ? "#{id}_#{s}" : id
    end

    def date_taken
      if @dates.takenunknown.to_i.zero?
        Date.parse @dates.taken
      else
        Time.at(@dates.posted.to_i).to_date
      end
    end

    def folder_path
      date_taken.strftime '%Y/%m/%d'
    end

    def original_url
      original = @sizes.find { it.label == 'Original' }
      size     = original || @sizes.last

      size.source
    end

    def slug
      s = title.slugify
      s.empty? ? nil : s
    end

    def to_h
      {
        date_taken:   date_taken.to_s,
        description:  description,
        extension:    extension,
        id:           id,
        media:        media,
        original_url: original_url,
        tags:         tags,
        title:        title
      }
    end
  end
end
