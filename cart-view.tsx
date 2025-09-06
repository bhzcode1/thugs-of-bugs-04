"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { ArrowLeft, Minus, Plus, Trash2, ShoppingBag } from "lucide-react"

interface CartViewProps {
  user: any
  onNavigateBack: () => void
}

export function CartView({ user, onNavigateBack }: CartViewProps) {
  // Mock cart items
  const [cartItems, setCartItems] = useState([
    {
      id: "1",
      title: "Vintage Leather Jacket",
      price: 45,
      quantity: 1,
      image: "/vintage-leather-jacket.png",
      seller: "sarah_vintage",
      condition: "Excellent",
    },
    {
      id: "2",
      title: "Wooden Coffee Table",
      price: 120,
      quantity: 1,
      image: "/wooden-coffee-table.png",
      seller: "furniture_lover",
      condition: "Very Good",
    },
  ])

  const updateQuantity = (id: string, newQuantity: number) => {
    if (newQuantity === 0) {
      removeItem(id)
      return
    }
    setCartItems((items) => items.map((item) => (item.id === id ? { ...item, quantity: newQuantity } : item)))
  }

  const removeItem = (id: string) => {
    setCartItems((items) => items.filter((item) => item.id !== id))
  }

  const subtotal = cartItems.reduce((sum, item) => sum + item.price * item.quantity, 0)
  const shipping = 5.99
  const total = subtotal + shipping

  const handleCheckout = () => {
    // Mock checkout process
    alert("Checkout functionality would be implemented here!")
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="sticky top-0 z-50 bg-card border-b border-border">
        <div className="container mx-auto px-4 py-3">
          <div className="flex items-center gap-4">
            <Button variant="ghost" size="sm" onClick={onNavigateBack}>
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Feed
            </Button>
            <h1 className="text-xl font-semibold">Shopping Cart</h1>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Cart Items */}
          <div className="lg:col-span-2">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <ShoppingBag className="h-5 w-5" />
                  Cart Items ({cartItems.length})
                </CardTitle>
              </CardHeader>
              <CardContent>
                {cartItems.length === 0 ? (
                  <div className="text-center py-8">
                    <ShoppingBag className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                    <p className="text-muted-foreground">Your cart is empty</p>
                    <Button onClick={onNavigateBack} className="mt-4">
                      Continue Shopping
                    </Button>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {cartItems.map((item) => (
                      <div key={item.id} className="flex items-center gap-4 p-4 border border-border rounded-lg">
                        <img
                          src={item.image || "/placeholder.svg"}
                          alt={item.title}
                          className="w-20 h-20 object-cover rounded-lg"
                        />
                        <div className="flex-1">
                          <h3 className="font-semibold">{item.title}</h3>
                          <p className="text-sm text-muted-foreground">Sold by {item.seller}</p>
                          <div className="flex items-center gap-2 mt-1">
                            <Badge variant="outline">{item.condition}</Badge>
                            <span className="font-bold text-primary">${item.price}</span>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => updateQuantity(item.id, item.quantity - 1)}
                          >
                            <Minus className="h-4 w-4" />
                          </Button>
                          <span className="w-8 text-center">{item.quantity}</span>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => updateQuantity(item.id, item.quantity + 1)}
                          >
                            <Plus className="h-4 w-4" />
                          </Button>
                        </div>
                        <Button variant="outline" size="sm" onClick={() => removeItem(item.id)}>
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>

          {/* Order Summary */}
          {cartItems.length > 0 && (
            <div className="lg:col-span-1">
              <Card>
                <CardHeader>
                  <CardTitle>Order Summary</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex justify-between">
                    <span>Subtotal</span>
                    <span>${subtotal.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Shipping</span>
                    <span>${shipping.toFixed(2)}</span>
                  </div>
                  <div className="border-t border-border pt-4">
                    <div className="flex justify-between font-bold text-lg">
                      <span>Total</span>
                      <span className="text-primary">${total.toFixed(2)}</span>
                    </div>
                  </div>
                  <Button onClick={handleCheckout} className="w-full">
                    Proceed to Checkout
                  </Button>
                  <p className="text-xs text-muted-foreground text-center">
                    Secure checkout powered by sustainable commerce
                  </p>
                </CardContent>
              </Card>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
