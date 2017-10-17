# Serializer for Search Result
class SearchResultSerializer < ActiveModel::Serializer

  attributes :count, :results
end
